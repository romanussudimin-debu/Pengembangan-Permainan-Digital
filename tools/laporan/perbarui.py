# Membuka .docx di LibreOffice (UNO), memperbarui semua daftar (isi/gambar/tabel), lalu menyimpan .docx dan .pdf.
import sys, os, time, subprocess, tempfile
sys.path.insert(0, "/root/.claude/skills/synced/52632906-1e43-4279-9220-3b8cdcbe4331_ffd0b7ed-40c2-4e4d-a26c-915335fd8a99/docx/scripts")
from office.soffice import get_soffice_env
import uno
from com.sun.star.beans import PropertyValue

masuk, keluar_docx, keluar_pdf = [os.path.abspath(a) for a in sys.argv[1:4]]
profil = tempfile.mkdtemp(prefix="lo_profil_")
proc = subprocess.Popen(["soffice", f"-env:UserInstallation=file://{profil}", "--headless", "--invisible", "--norestore",
                         "--accept=socket,host=127.0.0.1,port=2083;urp;"], env=get_soffice_env(),
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def prop(n, v):
    p = PropertyValue(); p.Name = n; p.Value = v; return p


ctx = None
lokal = uno.getComponentContext()
resolver = lokal.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", lokal)
for _ in range(60):
    try:
        ctx = resolver.resolve("uno:socket,host=127.0.0.1,port=2083;urp;StarOffice.ComponentContext")
        break
    except Exception:
        time.sleep(1)
smgr = ctx.ServiceManager
desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
doc = desktop.loadComponentFromURL(uno.systemPathToFileUrl(masuk), "_blank", 0, (prop("Hidden", True),))
idx = doc.getDocumentIndexes()
print("jumlah daftar:", idx.getCount())
for putaran in range(2):  # dua kali agar nomor halaman stabil setelah daftar terisi
    for i in range(idx.getCount()):
        idx.getByIndex(i).update()
doc.refresh()
for i in range(idx.getCount()):
    x = idx.getByIndex(i)
    print(" -", x.getImplementationName(), "| baris:", len(x.getAnchor().getString().splitlines()))
doc.storeToURL(uno.systemPathToFileUrl(keluar_docx), (prop("FilterName", "MS Word 2007 XML"),))
doc.storeToURL(uno.systemPathToFileUrl(keluar_pdf), (prop("FilterName", "writer_pdf_Export"),))
doc.close(True)
try:
    desktop.terminate()
except Exception:
    pass
proc.wait(timeout=30)
print("selesai")
