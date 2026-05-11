
# Debug brace balance for _BillDashboardPageState class
try:
    with open('app/lib/pages/bill_dashboard_page.dart', 'r') as f:
        lines = f.readlines()
except FileNotFoundError:
    print("File not found")
    exit(1)

balance = 0
active = False
start_line = 0

for i, line in enumerate(lines):
    line_num = i + 1
    
    # Class starts at line 29: class _BillDashboardPageState ...
    if 'class _BillDashboardPageState' in line:
        active = True
        start_line = line_num
        print(f"Class started at {line_num}")
    
    if active:
        # Simple count - ignoring comments/strings for now as a heuristic
        # (Assuming no weird braces in strings in this file)
        opens = line.count('{')
        closes = line.count('}')
        
        balance += opens
        balance -= closes
        
        # print(f"Line {line_num}: {balance} (+{opens} -{closes})")
        
        if balance == 0:
            print(f"Brace balance hit 0 at line {line_num}")
            print(f"Content: {line.strip()}")
            break

if balance > 0:
    print(f"Unexpected end of file. Final balance: {balance}")
