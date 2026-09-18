<?php
require_once(__DIR__ . '/student_config.php');
$currentPage = $currentPage ?? 'dashboard';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NovaTech Corp — Lab 03 Briefing (<?= htmlspecialchars($GLOBALS['STUDENT_ID']) ?>)</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
</head>
<body>
<nav class="navbar">
    <a href="index.php" class="brand">
        <div class="brand-logo">NT</div>
        <span>NovaTech Lab 03</span>
    </a>
    <ul class="nav-links">
        <li><a href="index.php"    class="<?= $currentPage==='dashboard'?'active':'' ?>">Mission Briefing</a></li>
        <li><a href="topology.php" class="<?= $currentPage==='topology' ?'active':'' ?>">Network Topology</a></li>
        <li><a href="tools.php"    class="<?= $currentPage==='tools'    ?'active':'' ?>">Tools Reference</a></li>
    </ul>
    <div class="user-badge">
        <div class="avatar">ID</div>
        <div class="user-info">
            <div class="user-name"><?= htmlspecialchars($GLOBALS['STUDENT_ID']) ?></div>
            <div class="user-role">Lab03 Instance</div>
        </div>
    </div>
</nav>
<div class="container">
