import re
import argparse

# Supported Ruby-to-C# mappings
RUBY_TO_CSHARP_KEYWORDS = {
    "def": "public void",
    "class": "public class",
    "end": "}",  # Block termination
    "if": "if",
    "elsif": "else if",
    "else": "else",
    "while": "while",
    "do": "{",
    "true": "true",
    "false": "false",
    "nil": "null"
}

# Tokenize Ruby Code
def tokenize_ruby_code(code):
    tokens = re.findall(r"[A-Za-z_][A-Za-z0-9_]*|\S", code)
    return tokens

# Parse Tokens to Build AST
def parse_tokens(tokens):
    ast = []
    stack = []

    for token in tokens:
        if token in ("class", "def", "if", "while", "else", "elsif", "do"):
            stack.append({"type": token, "body": []})
        elif token == "end":
            node = stack.pop()
            if stack:
                stack[-1]["body"].append(node)
            else:
                ast.append(node)
        elif stack:
            stack[-1]["body"].append({"type": "code", "value": token})
        else:
            ast.append({"type": "code", "value": token})

    return ast

# Transpile AST to C#
def transpile_to_csharp(ast):
    csharp_code = ""

    def transpile_node(node):
        nonlocal csharp_code

        if node["type"] == "class":
            csharp_code += f"{RUBY_TO_CSHARP_KEYWORDS['class']} {node['body'][0]['value']} {{\n"
            for child in node["body"][1:]:
                transpile_node(child)
            csharp_code += "}\n"
        elif node["type"] == "def":
            method_name = node["body"][0]["value"]
            csharp_code += f"    {RUBY_TO_CSHARP_KEYWORDS['def']} {method_name}() {{\n"
            for child in node["body"][1:]:
                transpile_node(child)
            csharp_code += "    }\n"
        elif node["type"] == "if":
            csharp_code += f"    {RUBY_TO_CSHARP_KEYWORDS['if']} ("
            condition = node["body"][0]["value"]
            csharp_code += f"{condition}) {{\n"
            for child in node["body"][1:]:
                transpile_node(child)
            csharp_code += "    }\n"
        elif node["type"] == "while":
            csharp_code += f"    {RUBY_TO_CSHARP_KEYWORDS['while']} ("
            condition = node["body"][0]["value"]
            csharp_code += f"{condition}) {{\n"
            for child in node["body"][1:]:
                transpile_node(child)
            csharp_code += "    }\n"
        elif node["type"] == "code":
            csharp_code += f"    {node['value']}\n"

    for node in ast:
        transpile_node(node)

    return csharp_code

# Read Ruby Code
def read_ruby_code(file_path):
    with open(file_path, "r") as file:
        return file.read()

# Write C# Code
def write_csharp_code(file_path, code):
    with open(file_path, "w") as file:
        file.write(code)

# Main Transpiler Function
def transpile_ruby_to_csharp(input_file, output_file):
    ruby_code = read_ruby_code(input_file)
    tokens = tokenize_ruby_code(ruby_code)
    ast = parse_tokens(tokens)
    csharp_code = transpile_to_csharp(ast)
    write_csharp_code(output_file, csharp_code)
    print(f"Transpilation complete. C# code written to {output_file}")

# Command-line Interface
def main():
    parser = argparse.ArgumentParser(description="Transpile Ruby code to C#.NET")
    parser.add_argument("input_file", type=str, help="Path to the Ruby input file")
    parser.add_argument("output_file", type=str, help="Path to the C# output file")
    args = parser.parse_args()

    transpile_ruby_to_csharp(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
