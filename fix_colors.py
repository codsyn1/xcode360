import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Import AppColors if not present
    if "import 'app_colors.dart';" not in content and "import 'package:xcode360/core/theme/app_colors.dart';" not in content:
        # Just simple import, assuming it's in lib/
        # Since app_colors.dart is in lib/, we might need relative import, but let's just do an absolute package import or relative
        # Let's count depth
        depth = filepath.count('/') - 5 # /Users/.../lib is depth 0
        prefix = '../' * depth if depth > 0 else ''
        import_stmt = f"import '{prefix}app_colors.dart';\n"
        
        # Insert after the first import
        content = re.sub(r"(import '.*?';\n)", r"\1" + import_stmt, content, count=1)

    # Some common replacements
    content = content.replace("isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7)", "AppColors.background(isDarkMode)")
    content = content.replace("isDarkMode ? const Color(0xFF121212) : const Color(0xFFF2F2F7)", "AppColors.background(isDarkMode)")
    content = content.replace("isDarkMode ? _pageBg : const Color(0xFFF2F2F7)", "AppColors.background(isDarkMode)")
    content = content.replace("isDarkMode ? _cardBg : Colors.white", "AppColors.card(isDarkMode)")
    
    # Bottom nav background
    content = content.replace("backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,", "backgroundColor: AppColors.bottomNav(isDarkMode),")

    # AppBar background
    content = content.replace("backgroundColor: isDarkMode ? _pageBg : const Color(0xFFF2F2F7),", "backgroundColor: AppColors.background(isDarkMode),")

    # Dialog background
    content = content.replace("backgroundColor: const Color(0xFF232323),", "backgroundColor: AppColors.card(isDarkMode),")
    content = content.replace("backgroundColor: Colors.white,", "backgroundColor: AppColors.card(isDarkMode),")

    # Text colors
    content = content.replace("color: isDarkMode ? Colors.white : Colors.black", "color: AppColors.textPrimary(isDarkMode)")
    content = content.replace("color: isDarkMode ? Colors.white70 : Colors.black54", "color: AppColors.textSecondary(isDarkMode)")
    content = content.replace("color: isDarkMode ? Colors.white54 : Colors.black54", "color: AppColors.textSecondary(isDarkMode)")
    content = content.replace("color: isDarkMode ? Colors.white38 : Colors.black38", "color: AppColors.textSecondary(isDarkMode)")

    with open(filepath, 'w') as f:
        f.write(content)

files_to_process = [
    "lib/dashboard_screen.dart",
    "lib/profile_screen.dart",
    "lib/community_screen.dart",
    "lib/chat_project_exchange_screen.dart",
    "lib/chat_list_screen.dart",
    "lib/subscription_screen.dart",
    "lib/subcategories_screen.dart",
    "lib/settings_screen.dart",
    "lib/users_profiles_screen.dart"
]

for file in files_to_process:
    if os.path.exists(file):
        process_file(file)
        print(f"Processed {file}")
