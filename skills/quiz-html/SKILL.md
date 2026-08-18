---
name: explain-diff-html
description: >
  Use when the user asks for a rich, interactive explanation of a code change, diff, branch, PR, or repository feature.
  Produces a self-contained HTML file with diagrams and an interactive JS quiz, and automatically opens it in the browser.
---

# Explain Diff (HTML Output)

Please make me a rich, interactive explanation of the specified code change, diff, branch, PR, or repository feature.

It should have these sections:

- **Background**: Explain the existing system relevant to this change. (You should broadly explore surrounding code for this.) We don't know how much the reader already knows, so include a deep background for beginners (note that it can be skipped if the reader is already familiar), and then a more narrow background directly relevant to the change.
- **Intuition**: Explain the core intuition for the code change. The focus here is to explain the essence, not the full details. Use concrete examples with toy data. Use figures and diagrams liberally.
- **Code**: Do a high-level walkthrough of the changes to the code. Group/order the changes in an understandable way.
- **Quiz**: Come up with five questions that test the reader's knowledge of this PR/code change. This should be medium difficulty, difficult enough that you actually need to understand the substance to answer them, but not gotchas. The goal is to help the reader make sure that they've actually understood. These should be presented as interactive multiple-choice questions, and when the user clicks, it tells them whether they were correct and gives feedback. Strictly follow the Quiz Quality & Anti-Bias Rules below.

### Quiz Quality & Anti-Bias Rules:

Treat quiz design as a core part of the explanation. Inspect all five questions as a set before generating HTML:
- **Balance Correct Option Positions**: Never default to putting the correct answer as option B (the second option) or in any single fixed position. Distribute correct answers evenly across choices (A, B, C, D) throughout the 5 questions.
- **Match Option Length and Detail**: Ensure all options (correct answer and distractors) are comparable in length, technical depth, specificity, and grammar. Do NOT make the correct answer conspicuously longer or more detailed than the distractors—shorten correct choices or expand distractors so length never gives away the answer.
- **Plausible Distractors**: Write distractors that represent realistic misunderstandings, subtle logic edge cases, or plausible alternative code paths. Avoid joke choices or obviously incorrect options.
- **No Early Visual or Source Cues**: Ensure correct answers are not exposed prior to click through CSS styles, DOM attributes, HTML structure, or accessibility text.

### Format & Output Specifications:

- Output a single self-contained HTML file which includes CSS and JavaScript. Make the whole thing one long page with section headers and a table of contents. Don't use tabs for the top-level structure. Basic responsive styling so you can view it on a phone is nice too.
- Write the file under `./docs/quiz/` in the current repo (create the directory if needed). The filename always starts with today's date in `YYYY-MM-DD-` format, e.g. `./docs/quiz/YYYY-MM-DD-explanation-<slug>.html`.
- Please write with the clarity and flow of Martin Kleppmann, making it engaging and written in classic style. Transitions between sections should be smooth.
- Some tips on diagrams: Pick a small number of diagram families that can be reused throughout the explanation to explain various cases.
  - A very simplified version of the UI that the user sees in the app, to explain UI changes.
  - A system diagram showing data flow or communication between components. Make sure to include example data here!
- Don't use ASCII diagrams. Always use simple HTML/CSS designs for your diagrams, HTML lists for lists of things, etc.
- For code blocks, always use `<pre>` tags. If you use a custom styled div instead, it **must** have `white-space: pre-wrap` in its CSS, or the browser will collapse all newlines into a single line. Before saving the file, scan each code block in the HTML source and confirm its CSS includes `white-space: pre` or `pre-wrap`.
- Use callouts for key concepts or definitions, important edge cases, etc.

### Automatic Rendering (Option 1):

- Immediately after writing the HTML file, execute a shell command to render the file in the browser:
  - macOS: `open ./docs/quiz/YYYY-MM-DD-explanation-<slug>.html`
