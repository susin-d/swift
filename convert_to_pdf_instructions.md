# Convert Markdown to PDF

To convert the generated workspace_structure_report.md to PDF, you can use one of the following methods:

## Option 1: Use VS Code Extension
- Install the "Markdown PDF" extension in VS Code.
- Open workspace_structure_report.md.
- Press `Ctrl+Shift+P` and select `Markdown PDF: Export (pdf)`.

## Option 2: Use Node.js (markdown-pdf)
1. Install markdown-pdf globally:
   ```sh
   npm install -g markdown-pdf
   ```
2. Run the conversion:
   ```sh
   markdown-pdf workspace_structure_report.md
   ```
   This will generate `workspace_structure_report.pdf` in the same directory.

## Option 3: Use Pandoc (if installed)
1. Install Pandoc from https://pandoc.org/
2. Run:
   ```sh
   pandoc workspace_structure_report.md -o workspace_structure_report.pdf
   ```

---

Choose the method that best fits your environment. The PDF will be created in the project root.
