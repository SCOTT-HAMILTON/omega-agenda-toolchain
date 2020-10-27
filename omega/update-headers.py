import re
import sys

print(sys.argv)
if len(sys.argv) < 3:
    exit(1)

to_add = sys.argv[1].lower()
new_header_path = sys.argv[2]
agenda_defs_file = "agenda_defs.h"

agenda_header = "agenda_def_"+to_add+".h"

def copy_headers(source, destination):
    with open(source, "r") as source_file, open(destination, "w") as destination_file:
        destination_file.write(source_file.read())

def add_agenda_include(content, agenda_header):
    includes = re.findall(r'((?:#include \"agenda_def_.*\.h\"\n){1,})', content, re.MULTILINE)[0]
    includes += '#include "'+agenda_header+'"\n'
    return re.sub(r'((?:#include \"agenda_def_.*\.h\"\n){1,})', includes, content, re.MULTILINE)

def write_agendas(content, agendas):
    # includes = re.findall(r'((?:#include \"agenda_def_.*\.h\"\n){1,})', content, re.MULTILINE)[0]
    replacement_text = "const AgendaDef agendas[AGENDA_NUMS] = {\n" \
        +',\n'.join(["\t\tagenda_"+agenda for agenda in agendas])+"\n};"
    return re.sub(r'const\ AgendaDef\ agendas\[AGENDA_NUMS\]\ =\ \{\n(:?(:?.*\n)*)\};', replacement_text, content, re.MULTILINE)


with open(agenda_defs_file, "r") as agenda_defs:
    content = agenda_defs.read()
    agendas = re.findall(r'const\ AgendaDef\ agendas\[AGENDA_NUMS\]\ =\ \{\n((.*\n)*)\};', content, re.MULTILINE)[0][0].split(',')
    agendas = list(map(lambda x: x.replace("\t", "").replace("\n", "").replace("agenda_",""), agendas))
    if to_add in agendas:
        print(to_add+' already in definitions, updating '+agenda_header)
        copy_headers(new_header_path, agenda_header)
    else:
        agendas += [to_add]
        content = add_agenda_include(content, agenda_header)
        content = write_agendas(content, agendas)
        with open(agenda_defs_file, 'w') as agenda_defs:
            agenda_defs.write(content)

