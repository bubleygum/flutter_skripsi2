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

$id = $_POST['id'] ?? '';
$sql = "SELECT * FROM notif
        WHERE idAnggota = '$id'";
$result = $mysqli->query($sql);

if ($result->num_rows > 0) {
  $data = array();
  while ($row = $result->fetch_assoc()) {
    $data[] = $row;
  }
  $response = ['success' => true, 'data' => $data];
} else {
  $response = ['success' => false, 'message' => "gagal get user data"];
}
header('Content-Type: application/json');
echo json_encode($response);
?>
