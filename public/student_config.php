<?php
// student_config.php
$info = '/srv/labs/lab03/data/.studentinfo';
$GLOBALS['STUDENT_ID']   = 'LAB03-UNPROVISIONED';
$GLOBALS['PENTEST_PASS'] = '(run first-boot setup)';
if (file_exists($info)) {
    foreach (file($info, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (str_starts_with($line, 'STUDENT_ID='))   $GLOBALS['STUDENT_ID']   = substr($line, 11);
        if (str_starts_with($line, 'PENTEST_PASS=')) $GLOBALS['PENTEST_PASS'] = substr($line, 13);
    }
}
