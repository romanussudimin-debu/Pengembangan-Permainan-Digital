"""Generator file .tscn untuk karakter placeholder (pemain, buta, bos).

Model disusun dari bentuk dasar Godot (CapsuleMesh, SphereMesh, CylinderMesh,
BoxMesh, TorusMesh). Jalankan ulang skrip ini bila ingin mengubah proporsi
placeholder:  python tools/buat_scene_karakter.py
Catatan: menjalankan ulang akan MENIMPA scene karakter (perubahan manual di editor hilang).
"""
import math
from pathlib import Path

AKAR = Path(__file__).resolve().parent.parent


def fmt(v):
    s = f"{v:.5f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def transform(pos=(0, 0, 0), rot=(0, 0, 0), skala=(1, 1, 1)):
    """Transform3D gaya .tscn (basis baris demi baris), Euler YXZ dalam derajat."""
    rx, ry, rz = (math.radians(a) for a in rot)
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    Rx = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    Ry = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    Rz = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

    R = mul(mul(Ry, Rx), Rz)
    B = [[R[i][j] * skala[j] for j in range(3)] for i in range(3)]
    nilai = [B[0][0], B[0][1], B[0][2], B[1][0], B[1][1], B[1][2], B[2][0], B[2][1], B[2][2], *pos]
    return "Transform3D(" + ", ".join(fmt(x) for x in nilai) + ")"


class Scene:
    def __init__(self):
        self.ext, self.sub, self.nodes = [], [], []
        self._mat = {}

    def ext_res(self, tipe, path):
        i = f"{len(self.ext) + 1}_e"
        self.ext.append(f'[ext_resource type="{tipe}" path="{path}" id="{i}"]')
        return i

    def sub_res(self, tipe, **props):
        i = f"{tipe}_{len(self.sub) + 1}"
        baris = [f'[sub_resource type="{tipe}" id="{i}"]']
        for k, v in props.items():
            baris.append(f"{k} = {v}")
        self.sub.append("\n".join(baris))
        return i

    def bahan(self, nama, warna, logam=False, emisi=None, transparan=False, unshaded=False):
        if nama in self._mat:
            return self._mat[nama]
        warna = tuple(warna) + ((1.0,) if len(warna) == 3 else ())
        props = {"resource_name": f'"{nama}"', "albedo_color": f"Color({', '.join(fmt(c) for c in warna)})"}
        if transparan:
            props["transparency"] = "1"
        if unshaded:
            props["shading_mode"] = "0"
        if logam:
            props["metallic"] = "0.75"
            props["roughness"] = "0.3"
        else:
            props["roughness"] = "0.8"
        if emisi:
            props["emission_enabled"] = "true"
            props["emission"] = f"Color({', '.join(fmt(c) for c in tuple(emisi) + (1.0,))})"
            props["emission_energy_multiplier"] = "2.0"
        i = self.sub_res("StandardMaterial3D", **props)
        self._mat[nama] = i
        return i

    def node(self, nama, tipe, induk=None, tf=None, **props):
        kepala = f'[node name="{nama}" type="{tipe}"'
        if induk is not None:
            kepala += f' parent="{induk}"'
        kepala += "]"
        baris = [kepala]
        if tf:
            baris.append(f"transform = {tf}")
        for k, v in props.items():
            baris.append(f"{k} = {v}")
        self.nodes.append("\n".join(baris))

    def mesh(self, nama, induk, tipe_mesh, bahan, pos=(0, 0, 0), rot=(0, 0, 0), skala=(1, 1, 1), bayangan=True, **mesh_props):
        m = self.sub_res(tipe_mesh, **{k: fmt(v) if isinstance(v, (int, float)) else v for k, v in mesh_props.items()})
        props = {"mesh": f'SubResource("{m}")', "surface_material_override/0": f'SubResource("{bahan}")'}
        if not bayangan:
            props["cast_shadow"] = "0"
        self.node(nama, "MeshInstance3D", induk, transform(pos, rot, skala), **props)

    def simpan(self, path, akar_script=None):
        langkah = len(self.ext) + len(self.sub) + 1
        isi = [f"[gd_scene load_steps={langkah} format=3]", ""]
        isi += self.ext + [""] if self.ext else []
        for s in self.sub:
            isi += [s, ""]
        for n in self.nodes:
            isi += [n, ""]
        Path(path).write_text("\n".join(isi), encoding="utf-8")
        print("ditulis:", path)


# ------------------------------------------------------------------ PEMAIN

def buat_pemain():
    s = Scene()
    skrip = s.ext_res("Script", "res://scripts/player/player.gd")
    skrip_kam = s.ext_res("Script", "res://scripts/player/kamera_orbit.gd")
    skrip_hp = s.ext_res("Script", "res://scripts/common/komponen_hp.gd")
    kulit = s.bahan("kulit_sogan", (0.42, 0.27, 0.16))
    emas = s.bahan("emas", (0.86, 0.66, 0.22), logam=True)
    marun = s.bahan("marun", (0.46, 0.08, 0.11))
    hijau = s.bahan("hijau", (0.17, 0.40, 0.22))
    sogan = s.bahan("sogan_tua", (0.28, 0.17, 0.09))
    hitam = s.bahan("hitam", (0.06, 0.05, 0.05))

    badan = s.sub_res("CapsuleShape3D", radius="0.4", height="2.0")
    hit = s.sub_res("CylinderShape3D", radius="1.1", height="2.0")
    lengan_cam = s.sub_res("SphereShape3D", radius="0.25")

    s.node("Pemain", "CharacterBody3D", None, None, collision_layer="2", collision_mask="5",
           script=f'ExtResource("{skrip}")')
    s.node("CollisionShape3D", "CollisionShape3D", ".", transform((0, 1.0, 0)), shape=f'SubResource("{badan}")')
    s.node("Model", "Node3D", ".")
    M = "Model"
    # Kaki
    for nama, x in (("KakiKiri", -0.15), ("KakiKanan", 0.15)):
        s.node(nama, "Node3D", M, transform((x, 0.9, 0)))
        s.mesh("Kaki", f"{M}/{nama}", "CapsuleMesh", kulit, (0, -0.44, 0), radius=0.11, height=0.88)
        s.mesh("GelangKaki", f"{M}/{nama}", "CylinderMesh", emas, (0, -0.72, 0), top_radius=0.12, bottom_radius=0.12, height=0.06)
    # Kain dodot marun, sabuk emas, sampur hijau
    s.mesh("Kain", M, "CylinderMesh", marun, (0, 0.86, 0), top_radius=0.28, bottom_radius=0.37, height=0.52)
    s.mesh("Sabuk", M, "CylinderMesh", emas, (0, 1.1, 0), top_radius=0.29, bottom_radius=0.29, height=0.08)
    for i, x in enumerate((-0.3, 0.3)):
        s.mesh(f"Sampur{i + 1}", M, "BoxMesh", hijau, (x, 0.82, -0.06), (0, 0, 8 if x < 0 else -8), size="Vector3(0.09, 0.55, 0.03)")
    # Badan, rompi (kotang) sogan berlis emas, kalung
    s.mesh("Badan", M, "CapsuleMesh", kulit, (0, 1.38, 0), radius=0.28, height=0.78)
    s.mesh("Kotang", M, "CylinderMesh", sogan, (0, 1.4, 0), top_radius=0.27, bottom_radius=0.3, height=0.42)
    s.mesh("LisKotang", M, "CylinderMesh", emas, (0, 1.6, 0), top_radius=0.275, bottom_radius=0.275, height=0.04)
    s.mesh("Kalung", M, "TorusMesh", emas, (0, 1.64, -0.02), (12, 0, 0), inner_radius=0.17, outer_radius=0.24)
    # Kepala & atribut
    s.mesh("Kepala", M, "SphereMesh", kulit, (0, 1.88, 0), radius=0.19, height=0.38)
    for i, x in enumerate((-0.07, 0.07)):
        s.mesh(f"Mata{i + 1}", M, "SphereMesh", hitam, (x, 1.91, -0.16), radius=0.03, height=0.06)
        s.mesh(f"Sumping{i + 1}", M, "BoxMesh", emas, (x * 2.9, 1.9, 0.02), (0, 0, -20 if x < 0 else 20), size="Vector3(0.04, 0.18, 0.1)")
    s.mesh("Jamang", M, "CylinderMesh", emas, (0, 2.0, 0), top_radius=0.2, bottom_radius=0.2, height=0.07)
    s.mesh("Gelung", M, "CylinderMesh", emas, (0, 2.12, 0.02), top_radius=0.09, bottom_radius=0.17, height=0.2)
    s.mesh("GarudaMungkur", M, "BoxMesh", emas, (0, 2.1, 0.17), (-25, 0, 0), size="Vector3(0.22, 0.2, 0.04)")
    s.mesh("Rambut", M, "BoxMesh", hitam, (0, 1.78, 0.14), size="Vector3(0.3, 0.34, 0.1)")
    # Praba (hiasan punggung bersayap, tanda ksatria sakti)
    for i, x in enumerate((-0.22, 0.22)):
        s.mesh(f"Praba{i + 1}", M, "BoxMesh", emas, (x, 1.6, 0.28), (15, 0, 35 if x < 0 else -35), size="Vector3(0.04, 0.55, 0.24)")
    # Lengan
    for nama, x in (("LenganKiri", -0.38), ("LenganKanan", 0.38)):
        L = f"{M}/{nama}"
        s.node(nama, "Node3D", M, transform((x, 1.62, 0)))
        s.mesh("Lengan", L, "CapsuleMesh", kulit, (0, -0.32, 0), radius=0.085, height=0.68)
        s.mesh("KelatBahu", L, "CylinderMesh", emas, (0, -0.08, 0), top_radius=0.11, bottom_radius=0.11, height=0.08)
        s.mesh("Gelang", L, "CylinderMesh", emas, (0, -0.55, 0), top_radius=0.1, bottom_radius=0.1, height=0.07)
    # Gada emas di tangan kanan
    L = f"{M}/LenganKanan"
    s.node("Gada", "Node3D", L, transform((0, -0.64, 0)))
    s.mesh("Gagang", f"{L}/Gada", "CylinderMesh", sogan, (0, 0, -0.22), (90, 0, 0), top_radius=0.035, bottom_radius=0.035, height=0.7)
    s.mesh("KepalaGada", f"{L}/Gada", "CylinderMesh", emas, (0, 0, -0.62), (-90, 0, 0), top_radius=0.14, bottom_radius=0.1, height=0.34, radial_segments=8)
    s.mesh("Ujung", f"{L}/Gada", "SphereMesh", emas, (0, 0, -0.82), radius=0.08, height=0.16)
    # Hitbox serangan
    s.node("Hitbox", "Area3D", M, transform((0, 1.0, -1.0)), collision_layer="0", collision_mask="4", monitorable="false")
    s.node("CollisionShape3D", "CollisionShape3D", f"{M}/Hitbox", None, shape=f'SubResource("{hit}")')
    # Kamera
    s.node("KameraRig", "Node3D", ".", transform((0, 1.7, 0)), script=f'ExtResource("{skrip_kam}")')
    s.node("SpringArm3D", "SpringArm3D", "KameraRig", None, shape=f'SubResource("{lengan_cam}")', spring_length="5.5", margin="0.2")
    s.node("Camera3D", "Camera3D", "KameraRig/SpringArm3D", None, current="true", fov="70.0")
    s.node("KomponenHP", "Node", ".", None, script=f'ExtResource("{skrip_hp}")')
    s.simpan(AKAR / "scenes/player/player.tscn")


# ------------------------------------------------------------------ RAKSASA (buta & bos)

def model_raksasa(s, M, kulit, kain, emas, putih, hitam, mata, rambut, senjata):
    for nama, x in (("KakiKiri", -0.28), ("KakiKanan", 0.28)):
        s.node(nama, "Node3D", M, transform((x, 1.1, 0)))
        s.mesh("Kaki", f"{M}/{nama}", "CapsuleMesh", kulit, (0, -0.55, 0), radius=0.18, height=1.15)
        s.mesh("GelangKaki", f"{M}/{nama}", "CylinderMesh", emas, (0, -0.9, 0), top_radius=0.2, bottom_radius=0.2, height=0.08)
    s.mesh("Kain", M, "CylinderMesh", kain, (0, 1.05, 0), top_radius=0.52, bottom_radius=0.64, height=0.62)
    s.mesh("Sabuk", M, "CylinderMesh", emas, (0, 1.38, 0), top_radius=0.56, bottom_radius=0.56, height=0.1)
    s.mesh("Badan", M, "CapsuleMesh", kulit, (0, 1.85, 0), radius=0.56, height=1.5)
    s.mesh("Perut", M, "SphereMesh", kulit, (0, 1.62, -0.18), radius=0.5, height=1.0)
    s.mesh("Kalung", M, "TorusMesh", emas, (0, 2.28, -0.05), (15, 0, 0), inner_radius=0.32, outer_radius=0.42)
    s.mesh("Kepala", M, "SphereMesh", kulit, (0, 2.68, 0), radius=0.42, height=0.84)
    s.mesh("Rambut", M, "BoxMesh", rambut, (0, 2.45, 0.36), size="Vector3(0.75, 0.95, 0.25)")
    s.mesh("Hidung", M, "SphereMesh", kulit, (0, 2.66, -0.42), radius=0.1, height=0.2)
    for i, x in enumerate((-0.16, 0.16)):
        s.mesh(f"Mata{i + 1}", M, "SphereMesh", putih, (x, 2.78, -0.33), radius=0.11, height=0.22)
        s.mesh(f"Pupil{i + 1}", M, "SphereMesh", mata, (x, 2.78, -0.43), radius=0.055, height=0.11)
        s.mesh(f"Taring{i + 1}", M, "CylinderMesh", putih, (x * 0.75, 2.47, -0.36), top_radius=0.05, bottom_radius=0.0, height=0.2)
        s.mesh(f"Anting{i + 1}", M, "TorusMesh", emas, (x * 2.7, 2.6, 0), (0, 0, 90), inner_radius=0.06, outer_radius=0.1)
    s.mesh("Mahkota", M, "CylinderMesh", emas, (0, 3.08, 0.04), top_radius=0.16, bottom_radius=0.3, height=0.24, radial_segments=8)
    for nama, x in (("LenganKiri", -0.72), ("LenganKanan", 0.72)):
        L = f"{M}/{nama}"
        s.node(nama, "Node3D", M, transform((x, 2.3, 0)))
        s.mesh("Lengan", L, "CapsuleMesh", kulit, (0, -0.52, 0), radius=0.16, height=1.12)
        s.mesh("KelatBahu", L, "CylinderMesh", emas, (0, -0.12, 0), top_radius=0.19, bottom_radius=0.19, height=0.1)
        s.mesh("Gelang", L, "CylinderMesh", emas, (0, -0.85, 0), top_radius=0.18, bottom_radius=0.18, height=0.09)
    if senjata:
        L = f"{M}/LenganKanan"
        s.mesh("GadaKayu", L, "CylinderMesh", senjata, (0, -1.02, -0.45), (-90, 0, 0), top_radius=0.16, bottom_radius=0.07, height=1.1, radial_segments=8)


def buat_buta():
    s = Scene()
    skrip = s.ext_res("Script", "res://scripts/enemies/buta.gd")
    skrip_hp = s.ext_res("Script", "res://scripts/common/komponen_hp.gd")
    kulit = s.bahan("kulit_buta_merah", (0.62, 0.2, 0.14))
    kain = s.bahan("kain_hijau_tua", (0.08, 0.22, 0.12))
    emas = s.bahan("emas", (0.86, 0.66, 0.22), logam=True)
    putih = s.bahan("putih", (0.95, 0.93, 0.86))
    hitam = s.bahan("hitam", (0.06, 0.05, 0.05))
    kayu = s.bahan("kayu_sogan", (0.45, 0.29, 0.16))
    bentuk = s.sub_res("CapsuleShape3D", radius="0.6", height="3.0")
    s.node("Buta", "CharacterBody3D", None, None, collision_layer="4", collision_mask="7", script=f'ExtResource("{skrip}")')
    s.node("CollisionShape3D", "CollisionShape3D", ".", transform((0, 1.5, 0)), shape=f'SubResource("{bentuk}")')
    s.node("Model", "Node3D", ".")
    model_raksasa(s, "Model", kulit, kain, emas, putih, hitam, hitam, hitam, kayu)
    s.node("KomponenHP", "Node", ".", None, script=f'ExtResource("{skrip_hp}")')
    s.simpan(AKAR / "scenes/enemies/buta.tscn")


def buat_bos():
    s = Scene()
    skrip = s.ext_res("Script", "res://scripts/boss/bos_raksasa.gd")
    skrip_hp = s.ext_res("Script", "res://scripts/common/komponen_hp.gd")
    kulit = s.bahan("kulit_bos_hijau", (0.16, 0.27, 0.16))
    kain = s.bahan("kain_marun", (0.46, 0.08, 0.11))
    emas = s.bahan("emas", (0.86, 0.66, 0.22), logam=True)
    putih = s.bahan("putih", (0.95, 0.93, 0.86))
    hitam = s.bahan("hitam", (0.06, 0.05, 0.05))
    mata = s.bahan("mata_merah", (0.9, 0.1, 0.05), emisi=(1.0, 0.15, 0.05))
    penanda = s.bahan("penanda_hantam", (0.95, 0.12, 0.08, 0.4), transparan=True, unshaded=True)
    bentuk = s.sub_res("CapsuleShape3D", radius="1.2", height="6.0")
    s.node("BosRaksasa", "CharacterBody3D", None, None, collision_layer="4", collision_mask="3", script=f'ExtResource("{skrip}")')
    s.node("CollisionShape3D", "CollisionShape3D", ".", transform((0, 3.0, 0)), shape=f'SubResource("{bentuk}")')
    s.node("Model", "Node3D", ".", transform(skala=(1.95, 1.95, 1.95)))
    model_raksasa(s, "Model", kulit, kain, emas, putih, hitam, mata, hitam, None)
    # Praba raksasa (lingkaran emas di punggung) & mahkota tinggi.
    s.mesh("PrabaBos", "Model", "TorusMesh", emas, (0, 2.5, 0.55), (90, 0, 0), inner_radius=0.55, outer_radius=0.68)
    s.mesh("MahkotaTinggi", "Model", "CylinderMesh", emas, (0, 3.35, 0.04), top_radius=0.03, bottom_radius=0.2, height=0.45, radial_segments=8)
    s.mesh("PenandaHantam", ".", "CylinderMesh", penanda, (0, 0.06, 0), bayangan=False, top_radius=6.5, bottom_radius=6.5, height=0.04, radial_segments=48)
    s.node("KomponenHP", "Node", ".", None, script=f'ExtResource("{skrip_hp}")')
    s.simpan(AKAR / "scenes/boss/bos_raksasa.tscn")


if __name__ == "__main__":
    buat_pemain()
    buat_buta()
    buat_bos()
