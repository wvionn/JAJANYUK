$headers = @{
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cGRqY3hzYnhqcGNmcnhiYnNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NzQ4OTEsImV4cCI6MjA5NDA1MDg5MX0.yU3YFlN1o3X021iFRbIcOImorAeREC_EIxgsEop4FCA"
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cGRqY3hzYnhqcGNmcnhiYnNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NzQ4OTEsImV4cCI6MjA5NDA1MDg5MX0.yU3YFlN1o3X021iFRbIcOImorAeREC_EIxgsEop4FCA"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}
$baseUrl = "https://wvpdjcxsbxjpcfrxbbsn.supabase.co/rest/v1"
$campusId = "37b8e9ce-034f-4531-b93e-182743e98fa5"

# ===== Insert 4 Vendors =====
$vendors = @(
    @{
        campus_id = $campusId
        name = "Warung Bu Sari"
        description = "Nasi Gudeg, Soto Betawi, Rendang, Sayur Asem"
        location = "Kantin Gedung A Lantai 1"
        phone = "081234567001"
        open_time = "07:30"
        close_time = "16:00"
        is_open = $true
        estimated_process_time = "10-15 menit"
        verification_status = "Terverifikasi"
    },
    @{
        campus_id = $campusId
        name = "K-Food Corner"
        description = "Tteokbokki, Ramyeon, Kimbap, Kimchi Fried Rice"
        location = "Kantin Gedung A Lantai 2"
        phone = "081234567002"
        open_time = "09:00"
        close_time = "17:00"
        is_open = $true
        estimated_process_time = "10-15 menit"
        verification_status = "Terverifikasi"
    },
    @{
        campus_id = $campusId
        name = "Snack Zone"
        description = "Dimsum, Pisang Goreng, Cireng, Tahu Crispy"
        location = "Lobi Utama"
        phone = "081234567003"
        open_time = "08:00"
        close_time = "17:00"
        is_open = $true
        estimated_process_time = "5-10 menit"
        verification_status = "Terverifikasi"
    },
    @{
        campus_id = $campusId
        name = "Seruput Yuk!"
        description = "Es Teh, Kopi Susu, Jus Buah, Boba, Milkshake"
        location = "Taman Kampus"
        phone = "081234567004"
        open_time = "08:00"
        close_time = "18:00"
        is_open = $true
        estimated_process_time = "5-10 menit"
        verification_status = "Terverifikasi"
    }
)

$vendorIds = @()
foreach ($v in $vendors) {
    $body = $v | ConvertTo-Json -Depth 3
    $result = Invoke-RestMethod -Method Post -Uri "$baseUrl/vendors" -Headers $headers -Body $body
    $vendorIds += $result.id
    Write-Host "Created vendor: $($result.name) => $($result.id)"
}

# ===== Insert Menus =====

# Stan 1: Warung Bu Sari (Makanan Tradisional)
$menus1 = @(
    @{ vendor_id=$vendorIds[0]; name="Nasi Gudeg"; description="Gudeg Jogja otentik dengan telur dan tahu bacem"; price=18000; category="Nasi Goreng" },
    @{ vendor_id=$vendorIds[0]; name="Soto Betawi"; description="Soto santan khas Betawi dengan daging sapi"; price=20000; category="Nasi Goreng" },
    @{ vendor_id=$vendorIds[0]; name="Rendang Padang"; description="Rendang daging sapi empuk bumbu rempah"; price=22000; category="Nasi Goreng" },
    @{ vendor_id=$vendorIds[0]; name="Sayur Asem"; description="Sayur asem segar dengan lauk tempe goreng"; price=15000; category="Nasi Goreng" },
    @{ vendor_id=$vendorIds[0]; name="Nasi Goreng Kampung"; description="Nasi goreng bumbu tradisional plus telur ceplok"; price=15000; category="Nasi Goreng" },
    @{ vendor_id=$vendorIds[0]; name="Mie Goreng Jawa"; description="Mie goreng khas Jawa dengan sayuran"; price=14000; category="Mie Goreng" },
    @{ vendor_id=$vendorIds[0]; name="Ayam Penyet"; description="Ayam goreng dipenyet sambel terasi pedas"; price=20000; category="Nasi Goreng" },
    @{ vendor_id=$vendorIds[0]; name="Nasi Pecel"; description="Nasi pecel sayuran dengan bumbu kacang"; price=14000; category="Nasi Goreng" }
)

# Stan 2: K-Food Corner (Korean Food)
$menus2 = @(
    @{ vendor_id=$vendorIds[1]; name="Tteokbokki"; description="Kue beras Korea dengan saus gochujang pedas manis"; price=18000; category="Dimsum" },
    @{ vendor_id=$vendorIds[1]; name="Ramyeon Original"; description="Mie instan Korea kuah pedas dengan telur"; price=16000; category="Mie Goreng" },
    @{ vendor_id=$vendorIds[1]; name="Kimbap"; description="Nasi gulung Korea isi daging dan sayuran"; price=20000; category="Dimsum" },
    @{ vendor_id=$vendorIds[1]; name="Kimchi Fried Rice"; description="Nasi goreng kimchi dengan telur mata sapi"; price=19000; category="Nasi Goreng" },
    @{ vendor_id=$vendorIds[1]; name="Japchae"; description="Bihun Korea tumis sayuran dan daging sapi"; price=22000; category="Mie Goreng" },
    @{ vendor_id=$vendorIds[1]; name="Korean Corn Dog"; description="Sosis mozzarella berlapis tepung crunchy"; price=15000; category="Dimsum" },
    @{ vendor_id=$vendorIds[1]; name="Ramyeon Cheese"; description="Ramyeon kuah pedas topping keju mozzarella"; price=20000; category="Mie Goreng" }
)

# Stan 3: Snack Zone (Cemilan Kecil)
$menus3 = @(
    @{ vendor_id=$vendorIds[2]; name="Dimsum Ayam"; description="Dimsum kukus isi ayam dan udang, 4 pcs"; price=12000; category="Dimsum" },
    @{ vendor_id=$vendorIds[2]; name="Dimsum Sapi"; description="Dimsum kukus isi daging sapi lembut, 4 pcs"; price=14000; category="Dimsum" },
    @{ vendor_id=$vendorIds[2]; name="Pisang Goreng Keju"; description="Pisang goreng crispy tabur keju dan susu"; price=10000; category="Dimsum" },
    @{ vendor_id=$vendorIds[2]; name="Cireng Rujak"; description="Cireng goreng crispy dengan saus rujak"; price=8000; category="Dimsum" },
    @{ vendor_id=$vendorIds[2]; name="Tahu Crispy"; description="Tahu goreng crispy dengan bumbu pedas"; price=8000; category="Dimsum" },
    @{ vendor_id=$vendorIds[2]; name="Kentang Goreng"; description="French fries crispy rasa original/BBQ"; price=12000; category="Dimsum" },
    @{ vendor_id=$vendorIds[2]; name="Sosis Bakar"; description="Sosis bakar saus blackpepper"; price=10000; category="Dimsum" },
    @{ vendor_id=$vendorIds[2]; name="Risol Mayo"; description="Risol isi ragout dan mayones, 3 pcs"; price=10000; category="Dimsum" }
)

# Stan 4: Seruput Yuk! (Minuman)
$menus4 = @(
    @{ vendor_id=$vendorIds[3]; name="Es Teh Manis"; description="Teh manis dingin segar khas Indonesia"; price=5000; category="Kopi" },
    @{ vendor_id=$vendorIds[3]; name="Kopi Susu Gula Aren"; description="Kopi robusta dengan susu dan gula aren asli"; price=15000; category="Kopi" },
    @{ vendor_id=$vendorIds[3]; name="Americano"; description="Espresso shot dengan air dingin/panas"; price=12000; category="Kopi" },
    @{ vendor_id=$vendorIds[3]; name="Jus Alpukat"; description="Jus alpukat segar dengan susu coklat"; price=13000; category="Kopi" },
    @{ vendor_id=$vendorIds[3]; name="Boba Brown Sugar"; description="Susu segar dengan boba brown sugar lembut"; price=16000; category="Kopi" },
    @{ vendor_id=$vendorIds[3]; name="Milkshake Oreo"; description="Milkshake vanilla dengan oreo crumble"; price=18000; category="Kopi" },
    @{ vendor_id=$vendorIds[3]; name="Jus Mangga"; description="Jus mangga harum manis segar"; price=12000; category="Kopi" },
    @{ vendor_id=$vendorIds[3]; name="Matcha Latte"; description="Matcha premium dengan susu segar"; price=17000; category="Kopi" }
)

$allMenus = $menus1 + $menus2 + $menus3 + $menus4

foreach ($m in $allMenus) {
    $body = $m | ConvertTo-Json -Depth 3
    $result = Invoke-RestMethod -Method Post -Uri "$baseUrl/menus" -Headers $headers -Body $body
    Write-Host "Created menu: $($result.name)"
}

Write-Host "`n===== SEEDING COMPLETE ====="
Write-Host "4 Vendors and $($allMenus.Count) Menus inserted successfully!"
