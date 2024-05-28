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
function getImageAsUint8List($filePath)
{
    $fileContent = file_get_contents($filePath);
    $binaryImage = '';
    for ($i = 0; $i < strlen($fileContent); $i++) {
        $binaryImage .= pack('C', ord($fileContent[$i]));
    }
    return $binaryImage;
}

$imagePath = 'http://localhost/imgSkripsi/';
$idKategori = $_POST['idKategori'] ?? '';
$sql = "SELECT * FROM kategori";
$result = $mysqli->query($sql);

if ($result->num_rows > 0) {
    $data = array();
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    $response = ['success' => true, 'data' => $data];
} else {
    $response = ['success' => false, 'message' => "gagal get kategori data"];
}
if ($idKategori != null) {
    $sql = "  SELECT p.*, i.imgName
    FROM produk p
    INNER JOIN kategori k ON p.idKategori = k.idKategori
    INNER JOIN (
      SELECT idProduk, MIN(idGambar) AS minIdGambar
      FROM imgproduk
      GROUP BY idProduk
    ) ig ON p.idProduk = ig.idProduk
    INNER JOIN imgproduk i ON p.idProduk = i.idProduk AND ig.minIdGambar = i.idGambar
    WHERE k.idKategori = $idKategori";
    $result = $mysqli->query($sql);

    if ($result->num_rows > 0) {
        $data = array();
        while ($row = $result->fetch_assoc()) {
            $imgPath = $imagePath . $row['imgName'];
            $imageData = getImageAsUint8List($imgPath);
            $row['imgName'] = base64_encode($imageData);
            $data[] = $row;
        }
        $response = ['success' => true, 'data' => $data];
    } else {
        $response = ['success' => false, 'message' => "gagal get produk dalam kategori data"];
    }
}
header('Content-Type: application/json');
echo json_encode($response);
?>