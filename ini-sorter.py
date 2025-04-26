import configparser
import shutil
import sys
import os

def sort_ini_file(filename):
    # Create backup
    backup_filename = filename + '.bak'
    shutil.copy2(filename, backup_filename)
    
    # Read the ini file
    config = configparser.RawConfigParser()
    config.optionxform = lambda option: option  # Preserve case of keys
    config.read(filename)

    # Sort sections and keys
    sorted_config = configparser.RawConfigParser()
    sorted_config.optionxform = lambda option: option

    for section in sorted(config.sections(), key=str.casefold):
        sorted_config.add_section(section)
        for key in sorted(config[section], key=str.casefold):
            sorted_config.set(section, key, config[section][key])

    # Write sorted content back to the original file
    with open(filename, 'w') as f:
        sorted_config.write(f)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {os.path.basename(sys.argv[0])} <filename.ini>")
        sys.exit(1)

    input_filename = sys.argv[1]
    if not os.path.isfile(input_filename):
        print(f"Error: File '{input_filename}' does not exist.")
        sys.exit(1)

    sort_ini_file(input_filename)
