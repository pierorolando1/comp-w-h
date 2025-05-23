package com.toylang;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import java.util.List;

import java_cup.runtime.Symbol;

public class ToyLanguageIDE extends JFrame {
    private JTextArea codeArea;
    private JTextArea outputArea;
    private JTable tokenTable;
    private DefaultTableModel tokenTableModel;
    private JLabel statusLabel;
    
    public ToyLanguageIDE() {
        initializeUI();
    }
    
    private void initializeUI() {
        setTitle("Toy Language IDE");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1000, 700);
        setLocationRelativeTo(null);
        
        // Create main panel with split panes
        JSplitPane mainSplit = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        mainSplit.setResizeWeight(0.6);
        
        // Left panel - Code editor
        JPanel leftPanel = createCodePanel();
        mainSplit.setLeftComponent(leftPanel);
        
        // Right panel - Token table and output
        JPanel rightPanel = createAnalysisPanel();
        mainSplit.setRightComponent(rightPanel);
        
        // Status bar
        statusLabel = new JLabel("Ready");
        statusLabel.setBorder(BorderFactory.createLoweredBevelBorder());
        
        // Add components to frame
        add(mainSplit, BorderLayout.CENTER);
        add(statusLabel, BorderLayout.SOUTH);
        
        // Load example code
        loadExampleCode();
    }
    
    private JPanel createCodePanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBorder(BorderFactory.createTitledBorder("Code Editor"));
        
        // Code text area
        codeArea = new JTextArea();
        codeArea.setFont(new Font("Monospaced", Font.PLAIN, 14));
        codeArea.setTabSize(4);
        JScrollPane codeScroll = new JScrollPane(codeArea);
        codeScroll.setPreferredSize(new Dimension(500, 500));
        
        // Buttons panel
        JPanel buttonPanel = new JPanel(new FlowLayout());
        JButton analyzeButton = new JButton("Analyze Code");
        JButton clearButton = new JButton("Clear");
        JButton loadButton = new JButton("Load File");
        JButton saveButton = new JButton("Save File");
        
        analyzeButton.addActionListener(e -> analyzeCode());
        clearButton.addActionListener(e -> clearAll());
        loadButton.addActionListener(e -> loadFile());
        saveButton.addActionListener(e -> saveFile());
        
        buttonPanel.add(analyzeButton);
        buttonPanel.add(clearButton);
        buttonPanel.add(loadButton);
        buttonPanel.add(saveButton);
        
        panel.add(codeScroll, BorderLayout.CENTER);
        panel.add(buttonPanel, BorderLayout.SOUTH);
        
        return panel;
    }
    
    private JPanel createAnalysisPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        
        // Create tabbed pane for tokens and output
        JTabbedPane tabbedPane = new JTabbedPane();
        
        // Token table tab
        JPanel tokenPanel = new JPanel(new BorderLayout());
        tokenPanel.setBorder(BorderFactory.createTitledBorder("Tokens"));
        
        String[] columnNames = {"Type", "Value", "Line", "Column"};
        tokenTableModel = new DefaultTableModel(columnNames, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        tokenTable = new JTable(tokenTableModel);
        tokenTable.setFont(new Font("Monospaced", Font.PLAIN, 12));
        JScrollPane tokenScroll = new JScrollPane(tokenTable);
        tokenPanel.add(tokenScroll, BorderLayout.CENTER);
        
        // Output tab
        JPanel outputPanel = new JPanel(new BorderLayout());
        outputPanel.setBorder(BorderFactory.createTitledBorder("Analysis Output"));
        
        outputArea = new JTextArea();
        outputArea.setFont(new Font("Monospaced", Font.PLAIN, 12));
        outputArea.setEditable(false);
        outputArea.setBackground(new Color(248, 248, 248));
        JScrollPane outputScroll = new JScrollPane(outputArea);
        outputPanel.add(outputScroll, BorderLayout.CENTER);
        
        tabbedPane.addTab("Tokens", tokenPanel);
        tabbedPane.addTab("Output", outputPanel);
        
        panel.add(tabbedPane, BorderLayout.CENTER);
        
        return panel;
    }
    
    private void analyzeCode() {
        String code = codeArea.getText();
        if (code.trim().isEmpty()) {
            showMessage("Please enter some code to analyze.", "Warning");
            return;
        }
        
        clearResults();
        
        try {
            // Lexical analysis
            StringReader reader = new StringReader(code);
            LexerCup lexer = new LexerCup(reader);
            //lexer.clearTokens();
            
            outputArea.append("=== LEXICAL ANALYSIS ===\n");
            outputArea.append("Scanning tokens...\n\n");
            
            // Collect all tokens
            Symbol symbol;
            do {
                symbol = lexer.next_token();
            } while (symbol.sym != Symbols.EOF);
            
            List<LexerCup.Token> tokens = lexer.getTokens();
            
            // Display tokens in table
            for (LexerCup.Token token : tokens) {
                tokenTableModel.addRow(new Object[]{
                    token.type, token.value, token.line, token.column
                });
            }
            
            outputArea.append("Found " + tokens.size() + " tokens.\n\n");
            
            // Syntax analysis
            outputArea.append("=== SYNTAX ANALYSIS ===\n");
            reader = new StringReader(code);
            lexer = new LexerCup(reader);
            Parser parser = new Parser(lexer);
            
            try {
                Symbol result = parser.parse();
                outputArea.append("✓ Syntax is VALID!\n");
                outputArea.append("Code parsed successfully without errors.\n");
                statusLabel.setText("Analysis completed - Syntax OK");
                statusLabel.setForeground(Color.GREEN.darker());
            } catch (Exception parseError) {
                outputArea.append("✗ Syntax ERROR!\n");
                outputArea.append("Parse error: " + parseError.getMessage() + "\n");
                statusLabel.setText("Analysis completed - Syntax ERROR");
                statusLabel.setForeground(Color.RED);
            }
            
        } catch (Exception e) {
            outputArea.append("✗ LEXICAL ERROR!\n");
            outputArea.append("Error: " + e.getMessage() + "\n");
            statusLabel.setText("Analysis failed - Lexical ERROR");
            statusLabel.setForeground(Color.RED);
        }
        
        outputArea.append("\n=== ANALYSIS COMPLETE ===\n");
    }
    
    private void clearAll() {
        codeArea.setText("");
        clearResults();
    }
    
    private void clearResults() {
        tokenTableModel.setRowCount(0);
        outputArea.setText("");
        statusLabel.setText("Ready");
        statusLabel.setForeground(Color.BLACK);
    }
    
    private void loadFile() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setFileFilter(new javax.swing.filechooser.FileFilter() {
            @Override
            public boolean accept(File f) {
                return f.isDirectory() || f.getName().toLowerCase().endsWith(".toy");
            }
            
            @Override
            public String getDescription() {
                return "Toy Language Files (*.toy)";
            }
        });
        
        if (fileChooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            try {
                File file = fileChooser.getSelectedFile();
                StringBuilder content = new StringBuilder();
                try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        content.append(line).append("\n");
                    }
                }
                codeArea.setText(content.toString());
                statusLabel.setText("Loaded: " + file.getName());
            } catch (IOException e) {
                showMessage("Error loading file: " + e.getMessage(), "Error");
            }
        }
    }
    
    private void saveFile() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setFileFilter(new javax.swing.filechooser.FileFilter() {
            @Override
            public boolean accept(File f) {
                return f.isDirectory() || f.getName().toLowerCase().endsWith(".toy");
            }
            
            @Override
            public String getDescription() {
                return "Toy Language Files (*.toy)";
            }
        });
        
        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            try {
                File file = fileChooser.getSelectedFile();
                if (!file.getName().toLowerCase().endsWith(".toy")) {
                    file = new File(file.getAbsolutePath() + ".toy");
                }
                
                try (PrintWriter writer = new PrintWriter(new FileWriter(file))) {
                    writer.print(codeArea.getText());
                }
                statusLabel.setText("Saved: " + file.getName());
            } catch (IOException e) {
                showMessage("Error saving file: " + e.getMessage(), "Error");
            }
        }
    }
    
    private void loadExampleCode() {
        String example = """
            // Example toy language program
            function factorial(int n) {
                if (n <= 1) {
                    return 1;
                } else {
                    return n * factorial(n - 1);
                }
            }
            
            var result = factorial(5);
            print(result);
            
            // Variable declarations
            int x = 10;
            string message = "Hello World";
            bool flag = true;
            
            // Control structures
            if (x > 5) {
                print("x is greater than 5");
            }
            
            while (x > 0) {
                x = x - 1;
            }
            """;
        codeArea.setText(example);
    }
    
    private void showMessage(String message, String title) {
        JOptionPane.showMessageDialog(this, message, title, 
                                    title.equals("Error") ? JOptionPane.ERROR_MESSAGE : 
                                    JOptionPane.WARNING_MESSAGE);
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception e) {
                // Use default look and feel
            }
            
            new ToyLanguageIDE().setVisible(true);
        });
    }
}
