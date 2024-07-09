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
$sql = "SELECT * 
        FROM pengajuan
        WHERE idAnggota = '$id' AND statusPelunasan = 0 AND statusTransfer = 1";
$result = $mysqli->query($sql);

$data = null; 

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc(); 
    $data = $row;

    $sql2 = "SELECT * 
            FROM pembayaran
            WHERE idAnggota = '$id'";
    $result2 = $mysqli->query($sql2);
    if ($result2->num_rows > 0) {
        while ($row2 = $result2->fetch_assoc()) {
            $data['pembayaran'][] = array(
                'idPembayaran' => $row2['id'],
                'bulan' => $row2['bulan'],
                'tahun' => $row2['tahun'],
                'cicilan' => $row2['cicilan'],
                'tglPembayaran' => $row2['tglPembayaran'],
            );
        }
    } else {
        $data['pembayaran'][] = array(
            'idPembayaran' => 0,
            'bulan' => 0,
            'tahun' => 0,
            'cicilan' => 0,
            'tglPembayaran' => 0,
        );
    }

    $sisa = $data['jumlahPengajuan'] + $data['bunga'] - array_sum(array_column($data['pembayaran'], 'cicilan'));
    $data['sisa'] = $sisa;

    $response = ['success' => true, 'data' => $data];
} else {
    $response = ['success' => false, 'message' => "tidak ada pengajuan aktif"];
}

header('Content-Type: application/json');
echo json_encode($response);
?>
