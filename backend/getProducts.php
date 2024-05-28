<?php
function cors()
{
  if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: *");
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
  die("Connection failed: ". $mysqli->connect_error);
}

function getImageAsUint8List($filePath) {
  $fileContent = file_get_contents($filePath);
  $binaryImage = '';
  for ($i = 0; $i < strlen($fileContent); $i++) {
    $binaryImage.= pack('C', ord($fileContent[$i]));
  }
  return $binaryImage;
}

$imagePath = 'http://localhost/imgSkripsi/';
$idProduk = $_POST['idProduk']?? '';
$sql = "  SELECT p.*, i.imgName
FROM produk p
LEFT JOIN imgproduk i ON p.idProduk = i.idProduk AND i.idGambar = (
  SELECT MIN(idGambar)
  FROM imgproduk
  WHERE idProduk = p.idProduk
)";
$result = $mysqli->query($sql);

if ($result->num_rows > 0) {
  $data = array();
  while ($row = $result->fetch_assoc()) {
    $imgPath = $imagePath. $row['imgName'];
    $imageData = getImageAsUint8List($imgPath);
    $row['imgName'] = base64_encode($imageData);
    $data[] = $row;
  }
  $response = ['success' => true, 'data' => $data];
} else {
  $response = ['success' => false, 'message' => "gagal get user data"];
}
if ($idProduk!= null) {
  $sql = " SELECT p.*, GROUP_CONCAT(i.imgName SEPARATOR ',') AS imgNames
  FROM produk p
  LEFT JOIN imgproduk i ON p.idProduk = i.idProduk
  WHERE p.idProduk = $idProduk
  GROUP BY p.idProduk";
  $result = $mysqli->query($sql);

  if ($result->num_rows > 0) {
    $data = array();
    while ($row = $result->fetch_assoc()) {
      $imgNames = explode(',', $row['imgNames']);
      $images = array();
      foreach ($imgNames as $imgName) {
        $imgPath = $imagePath. $imgName;
        $imageData = getImageAsUint8List($imgPath);
        $images[] = base64_encode($imageData);
      }
      $row['imgNames'] = $images;
      $data[] = $row;
    }
    $response = ['success' => true, 'data' => $data];
  } else {
    $response = ['success' => false, 'message' => "gagal get user data"];
  }
}
header('Content-Type: application/json');
echo json_encode($response);
?>