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

// Login
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';
$stmt = $mysqli->prepare("SELECT * FROM anggotakoperasi WHERE email = ? AND password = ?");
$stmt->bind_param("ss", $email, $password);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
  $data = array();
  while ($row = $result->fetch_assoc()) {
    $data[] = $row;
    if ($row['aktif'] == 0) {
      $response = ['success' => false, 'message' => "Your account is not active. Please contact the administrator."];
      break;
    }
  }
  if (!isset($response)) {
    $response = ['success' => true, 'data' => $data];
  }
} else {
  $response = ['success' => false, 'message' => "Invalid email or password"];
}
header('Content-Type: application/json');
echo json_encode($response);
?>
