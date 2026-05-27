#!/usr/bin/env python3
"""
Parse coverage.json produced by:
  pytest --cov=platform_ingestion --cov-report=json:.coverage.json --cov-branch

Emits four sections to stdout:
  GAP A   — functions/methods with zero executed lines (never called by any test)
  PARTIAL — modules with some uncovered lines/branches (exact line numbers included)
  FULL    — modules where every statement and branch is covered
"""
import ast
import json
import sys
from pathlib import Path


def _find_functions(source: str, filepath: str) -> list[dict]:
    """Return list of {name, qual_name, start_line, end_line} for every
    function and method definition in the source.  Skips abstract methods,
    property-only stubs, and __init__ bodies that are just `pass` or `...`.
    """
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return []

    results = []

    class Visitor(ast.NodeVisitor):
        def __init__(self):
            self._class_stack: list[str] = []

        def visit_ClassDef(self, node: ast.ClassDef):
            self._class_stack.append(node.name)
            self.generic_visit(node)
            self._class_stack.pop()

        def _is_trivial(self, node) -> bool:
            """True if the body is only pass/... (no real logic)."""
            body = node.body
            # Strip leading docstring
            if body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant):
                body = body[1:]
            if not body:
                return True
            return all(
                isinstance(s, (ast.Pass,)) or
                (isinstance(s, ast.Expr) and isinstance(s.value, ast.Constant) and s.value.value is ...)
                for s in body
            )

        def visit_FunctionDef(self, node):
            self._record(node)

        def visit_AsyncFunctionDef(self, node):
            self._record(node)

        def _record(self, node):
            # Skip abstract methods — they're intentionally not called
            for decorator in node.decorator_list:
                if isinstance(decorator, ast.Name) and decorator.id == "abstractmethod":
                    self.generic_visit(node)
                    return
                if isinstance(decorator, ast.Attribute) and decorator.attr == "abstractmethod":
                    self.generic_visit(node)
                    return

            # Skip trivial stubs (pass / ...)
            if self._is_trivial(node):
                self.generic_visit(node)
                return

            qual = ".".join(self._class_stack + [node.name]) if self._class_stack else node.name
            end_line = getattr(node, "end_lineno", node.lineno)
            results.append({
                "name": node.name,
                "qual_name": qual,
                "start_line": node.lineno,
                "end_line": end_line,
            })
            # Still recurse so nested functions are captured
            self.generic_visit(node)

    Visitor().visit(tree)
    return results


def _to_ranges(lines: list[int]) -> str:
    """Convert a sorted list of ints into a compact range string."""
    if not lines:
        return ""
    lines = sorted(lines)
    ranges = []
    start = prev = lines[0]
    for n in lines[1:]:
        if n == prev + 1:
            prev = n
        else:
            ranges.append(f"{start}-{prev}" if start != prev else str(start))
            start = prev = n
    ranges.append(f"{start}-{prev}" if start != prev else str(start))
    return ", ".join(ranges)


def main() -> None:
    cov_file = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".coverage.json")
    if not cov_file.exists():
        sys.exit(
            f"Coverage file not found: {cov_file}\n"
            "Run: pytest --cov=platform_ingestion --cov-report=json:.coverage.json "
            "--cov-branch -m 'not integration' -q --tb=no"
        )

    data = json.loads(cov_file.read_text())
    files = data.get("files", {})

    # Resolve the repo root — coverage paths are relative to it
    repo_root = cov_file.parent

    module_results = []
    gap_a_functions: list[dict] = []   # functions with zero executed lines

    for filepath, info in sorted(files.items()):
        if not filepath.startswith("platform_ingestion/"):
            continue
        if "__pycache__" in filepath or filepath.endswith("__init__.py"):
            continue

        summary = info["summary"]
        missing_lines: list[int] = info.get("missing_lines", [])
        executed_lines: set[int] = set(info.get("executed_lines", []))
        missing_branches = info.get("missing_branches", [])

        total_stmts = summary.get("num_statements", 0)
        covered_stmts = summary.get("covered_lines", len(executed_lines))
        pct = summary.get("percent_covered", 0.0)

        module_results.append({
            "file": filepath,
            "total": total_stmts,
            "covered": covered_stmts,
            "missing_lines": missing_lines,
            "missing_branches": missing_branches,
            "pct": pct,
        })

        # ── Function-level Gap A ──────────────────────────────────────────────
        abs_path = repo_root / filepath
        if not abs_path.exists():
            continue
        try:
            source = abs_path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue

        for fn in _find_functions(source, filepath):
            fn_lines = set(range(fn["start_line"], fn["end_line"] + 1))
            covered_in_fn = fn_lines & executed_lines
            if not covered_in_fn:
                gap_a_functions.append({
                    "file": filepath,
                    "qual_name": fn["qual_name"],
                    "start_line": fn["start_line"],
                    "end_line": fn["end_line"],
                    "size": fn["end_line"] - fn["start_line"] + 1,
                })

    # Sort by file then line for readability
    gap_a_functions.sort(key=lambda x: (x["file"], x["start_line"]))

    partial = [r for r in module_results if 0 < r["covered"] < r["total"]]
    full = [
        r for r in module_results
        if r["covered"] >= r["total"] and r["total"] > 0 and not r["missing_branches"]
    ]
    branch_only = [
        r for r in module_results
        if r["covered"] >= r["total"] and r["total"] > 0 and r["missing_branches"]
    ]

    # ── GAP A — function level ────────────────────────────────────────────────
    print("=" * 80)
    print(f"GAP A — Functions/methods never called by any test ({len(gap_a_functions)} found)")
    print("=" * 80)
    if gap_a_functions:
        current_file = None
        for fn in gap_a_functions:
            if fn["file"] != current_file:
                current_file = fn["file"]
                print(f"\n  {fn['file']}")
            loc = f"L{fn['start_line']}-{fn['end_line']}" if fn["start_line"] != fn["end_line"] else f"L{fn['start_line']}"
            print(f"    {fn['qual_name']:<55} {loc}  ({fn['size']} lines)")
    else:
        print("  (none)")

    # ── PARTIAL ───────────────────────────────────────────────────────────────
    print()
    print("=" * 80)
    print(f"PARTIAL — Some lines/branches uncovered ({len(partial)} modules)")
    print("=" * 80)
    if partial:
        for r in sorted(partial, key=lambda x: x["pct"]):
            print(f"\n  {r['file']}  ({r['pct']:.0f}% — {len(r['missing_lines'])} missing lines)")
            if r["missing_lines"]:
                ranges = _to_ranges(r["missing_lines"])
                print(f"    missing lines : {ranges}")
            if r["missing_branches"]:
                branch_str = ", ".join(f"{b[0]}→{b[1]}" for b in r["missing_branches"][:15])
                if len(r["missing_branches"]) > 15:
                    branch_str += f" ... +{len(r['missing_branches'])-15} more"
                print(f"    missing branches: {branch_str}")
    else:
        print("  (none)")

    # ── BRANCH-ONLY GAPS ─────────────────────────────────────────────────────
    if branch_only:
        print()
        print("=" * 80)
        print(f"BRANCH GAPS — All lines hit but branches missing ({len(branch_only)} modules)")
        print("=" * 80)
        for r in sorted(branch_only, key=lambda x: -len(x["missing_branches"])):
            branch_str = ", ".join(f"{b[0]}→{b[1]}" for b in r["missing_branches"][:15])
            if len(r["missing_branches"]) > 15:
                branch_str += f" ... +{len(r['missing_branches'])-15} more"
            print(f"\n  {r['file']}")
            print(f"    missing branches: {branch_str}")

    # ── FULL ─────────────────────────────────────────────────────────────────
    print()
    print("=" * 80)
    print(f"FULL — All statements and branches covered ({len(full)} modules)")
    print("=" * 80)
    for r in sorted(full, key=lambda x: x["file"]):
        print(f"  ✓  {r['file']}  ({r['total']} stmts)")

    # ── SUMMARY ──────────────────────────────────────────────────────────────
    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"  Total modules         : {len(module_results)}")
    print(f"  Gap A functions       : {len(gap_a_functions)}")
    print(f"  Partial modules       : {len(partial)}")
    print(f"  Branch-gap modules    : {len(branch_only)}")
    print(f"  Fully covered modules : {len(full)}")


if __name__ == "__main__":
    main()
