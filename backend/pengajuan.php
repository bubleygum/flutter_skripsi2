<?php
function cors()
{
    if (isset($_SERVER['HTTP_ORIGIN'])) {
        header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 86400');
    }

    if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {

        if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
            header("Access-Control-Allow-Methods: GET, POST, OPTIONS");

        if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
            header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");

        exit(0);
    }
}
cors();

$mysqli = new mysqli("localhost", "root", "", "skripsi");
if ($mysqli->connect_error) {
    die("Connection failed: " . $mysqli->connect_error);
}
$req = $_POST['req'] ?? '';
$idAnggota = $_POST['idAnggota'] ?? '';
$nama = $_POST['nama'] ?? '';
$jumlahPengajuan = $_POST['jumlahPengajuan'] ?? '';
$lamaPinjaman = $_POST['lamaPinjaman'] ?? '';
$bunga = $_POST['bunga'] ?? '';
$status = 0;
$statusTransfer = 0;
$tglPinjaman = date("Y-m-d");

if ($req == "upload") {
    function generateUniqueFileName($targetDir, $idAnggota, $originalFileName)
    {
        $extension = pathinfo($originalFileName, PATHINFO_EXTENSION);
        $uniqueName = $idAnggota . '.' . $extension;
        $counter = 1;

        while (file_exists($targetDir . $uniqueName)) {
            $uniqueName = $idAnggota . '_' . $counter . '.' . $extension;
            $counter++;
        }

        return $uniqueName;
    }

    if (isset($_FILES["image"])) {
        $targetDir = "C:/xampp/htdocs/imgSkripsi/";

        if (!empty($_FILES["image"]["tmp_name"])) {
            $originalFileName = basename($_FILES["image"]["name"]);
            $uniqueFileName = generateUniqueFileName($targetDir, $idAnggota, $originalFileName);
            $targetFile = $targetDir . $uniqueFileName;

            $imageFileType = strtolower(pathinfo($targetFile, PATHINFO_EXTENSION));
            $check = getimagesize($_FILES["image"]["tmp_name"]);

            if ($check === false || empty($_FILES["image"]["tmp_name"])) {
                $response = ['success' => false, 'message' => 'File is not an image or path is empty.'];
            } else if (file_exists($targetFile)) {
                $response = ['success' => false, 'message' => 'Sorry, file already exists.'];
            } else if ($_FILES["image"]["size"] > 500000) {
                $response = ['success' => false, 'message' => 'Sorry, your file is too large.'];
            } else if ($imageFileType != "jpg" && $imageFileType != "png" && $imageFileType != "jpeg" && $imageFileType != "gif") {
                $response = ['success' => false, 'message' => 'Sorry, only JPG, JPEG, PNG & GIF files are allowed.'];
            } else {
                $checkStmt = $mysqli->prepare("SELECT COUNT(*) FROM pengajuan WHERE idAnggota = ? AND statusPelunasan = 0");
                $checkStmt->bind_param("i", $idAnggota);
                $checkStmt->execute();
                $checkStmt->bind_result($count);
                $checkStmt->fetch();
                $checkStmt->close();

                if ($count > 0) {
                    $response = ['success' => false, 'message' => 'Pengajuan gagal, hanya bisa mengajukan 1 pengajuan.'];
                } else {
                    if (move_uploaded_file($_FILES["image"]["tmp_name"], $targetFile)) {
                        $tipePengajuan = 1;
                        $stmt = $mysqli->prepare("INSERT INTO `pengajuan` (`idAnggota`, `nama`,`tipePengajuan`, `status`, `dokumen`, `statusTransfer`, `jumlahPengajuan`,`bunga`,`lamaPinjaman`,`tglPinjaman`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                        $stmt->bind_param("isiisiddis", $idAnggota, $nama, $tipePengajuan, $status, $uniqueFileName, $statusTransfer, $jumlahPengajuan, $bunga, $lamaPinjaman, $tglPinjaman);
                        if ($stmt->execute()) {
                            $response = ['success' => true, 'message' => 'Data uploaded successfully.', 'jumlahPengajuan' => $jumlahPengajuan];
                        } else {
                            $response = ['success' => false, 'message' => 'Failed to insert data in the database. Error: ' . $stmt->error];
                        }

                        $stmt->close();
                    } else {
                        $response = ['success' => false, 'message' => 'Sorry, there was an error uploading your file. Error: ' . $_FILES["image"]["error"]];
                    }
                }
            }
        } else {
            $response = ['success' => false, 'message' => 'Image file not found.'];
        }
    } else {
        $response = ['success' => false, 'message' => 'Image file not found.'];
    }

} else if ($req == "market") {
    $checkStmt = $mysqli->prepare("SELECT COUNT(*) FROM pengajuan WHERE idAnggota = ? AND statusPelunasan = 0");
    $checkStmt->bind_param("i", $idAnggota);
    $checkStmt->execute();
    $checkStmt->bind_result($count);
    $checkStmt->fetch();
    $checkStmt->close();

    if ($count > 0) {
        $response = ['success' => false, 'message' => 'Pengajuan gagal, hanya bisa mengajukan 1 pengajuan.'];
    } else {
        $idProduk = $_POST['idProduk'] ?? '';
        $namaProduk = $_POST['namaProduk'] ?? '';
        $tipePengajuan = 2;
        $stmt = $mysqli->prepare("INSERT INTO `pengajuan` (`idAnggota`, `nama`, `tipePengajuan`, `status`, `dokumen`, `statusTransfer`, `jumlahPengajuan`,`bunga`, `lamaPinjaman`,`tglPinjaman`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

        $stmt->bind_param("isiisiddis", $idAnggota, $nama, $tipePengajuan, $status, $namaProduk, $statusTransfer, $jumlahPengajuan, $bunga, $lamaPinjaman, $tglPinjaman);

        if ($stmt->execute()) {
            $response = ['success' => true, 'message' => 'Data uploaded successfully.', 'jumlahPengajuan' => $jumlahPengajuan];
        } else {
            $response = ['success' => false, 'message' => 'Failed to insert data in the database. Error: ' . $stmt->error];
        }
        $stmt->close();
    }
} 
else if ($req == "getMaxLama"){
    $sql = "SELECT * FROM lamacicilan LIMIT 1";
    $result = $mysqli->query($sql);
    if ($result === false || $result->num_rows == 0) {
        $response = ['success' => false, 'message' => "Failed to retrieve lama cicilan data"];
    } else {
        $data = $result->fetch_assoc();
        $response = ['success' => true, 'data' => $data];
    }
}
else {
    $response = ['success' => false, 'message' => 'Invalid request.'];
}

header('Content-Type: application/json');
echo json_encode($response);
?>
