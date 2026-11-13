# Memindahkan w:sectPr ke posisi yang benar di dalam w:pPr (sebelum pPrChange, setelah elemen lain).
import sys, zipfile, shutil
from lxml import etree
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
src = sys.argv[1]; tmp = src + ".tmp"
zin = zipfile.ZipFile(src)
zout = zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED)
for item in zin.infolist():
    data = zin.read(item.filename)
    if item.filename == "word/document.xml":
        root = etree.fromstring(data)
        n = 0
        for ppr in root.iter(f"{{{W}}}pPr"):
            sp = ppr.find(f"{{{W}}}sectPr")
            if sp is None:
                continue
            ppr.remove(sp)
            chg = ppr.find(f"{{{W}}}pPrChange")
            if chg is not None:
                chg.addprevious(sp)
            else:
                ppr.append(sp)
            n += 1
        print("sectPr dipindah:", n)
        data = etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)
    zout.writestr(item, data)
zout.close(); zin.close()
shutil.move(tmp, src)
