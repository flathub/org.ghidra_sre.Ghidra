#!/usr/bin/env python3

import argparse
import logging
import os
import re

def extract_dependencies_to_table(in_file, out_file, version):
    with open(in_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Isolate the entire ext.deps block
    deps_match = re.search(r'ext\.deps\s*=\s*\[(.*?)\n\]\n\n', content, re.DOTALL)
    if not deps_match:
        print("Error: Could not locate the ext.deps block.")
        return

    deps_content = deps_match.group(1)

    # Split the list of maps by the closing bracket pattern "\n\t],"
    # This safely separates each dictionary without breaking internal lists/closures
    blocks = deps_content.split('\n\t],')

    results = []
    for block in blocks:
        # Clean up any remaining brackets for the very last block in the array
        block = re.sub(r'\n\t\]$', '', block).strip()
        if not block:
            continue

        name_m = re.search(r'name:\s*"([^"]+)"', block)
        url_m = re.search(r'url:\s*"([^"]+)"', block)
        sha_m = re.search(r'sha256:\s*"([^"]+)"', block)

        # Match everything after 'destination:' up to the end of the block
        dest_m = re.search(r'destination:\s*(.*)', block, re.DOTALL)

        if name_m and url_m and sha_m and dest_m:
            dest = dest_m.group(1).strip()

            # Remove an optional ', eclipse: true' from the end if it exists
            dest = re.sub(r',\s*eclipse:\s*true\s*$', '', dest, flags=re.DOTALL).strip()

            # Flatten multi-line closures (like the z3 dest blocks) into a single line 
            # to prevent it from breaking the Markdown table rendering
            dest_single_line = re.sub(r'\s+', ' ', dest)

            results.append({
                'name': name_m.group(1),
                'sha256': sha_m.group(1),
                'url': url_m.group(1),
                'destination': dest_single_line
            })

    if not results:
        print("No dependencies parsed.")
        return

    first = True
    with open(out_file, 'w') as fp:
        fp.write('[\n')
        for r in results:
            if r['name'].startswith('z3'):
                continue

            url = r['url']
            if '${RELEASE_VERSION}' in url:
                if version == '':
                    continue
                url = url.replace(r'${RELEASE_VERSION}', version)

            sha = r['sha256']

            dest = r['destination']
            if dest == 'FLAT_REPO_DIR':
                dest = 'dependencies/flatRepo'
            elif dest == 'FID_DIR':
                dest = 'dependencies/fidb'
            elif dest.startswith('file("'):
                dest = dest.replace(r'${DEPS_DIR}', 'dependencies')[6:-2]
            elif dest.startswith('[file("'):
                dest = 'dependencies/Debugger-rmi-trace/'

            if not first:
                fp.write( ',\n')
            else:
                first = False
                fp.write('\n')

            fp.write( '   {\n')
            fp.write( '       "type": "file",\n')
            fp.write(f'       "url": "{url}",\n')
            fp.write(f'       "sha256": "{sha}",\n')
            fp.write(f'       "dest": "{dest}"\n')
            fp.write( '   }')
        fp.write('\n]\n')

def main():
    logging.basicConfig(
        level=os.environ.get('LOGLEVEL', 'WARNING').upper()
    )
    parser = argparse.ArgumentParser()
    parser.add_argument('input', help='The fetchDependencies.gradle file')
    parser.add_argument('output', help='The output JSON sources file')
    parser.add_argument('--version',
                        help='The current Ghidra version',
                        default='')

    args = parser.parse_args()

    extract_dependencies_to_table(args.input, args.output, args.version)

if __name__ == '__main__':
    main()
