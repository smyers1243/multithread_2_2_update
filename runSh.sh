date
echo 00 
date
perl update_driver.pl --dir /home/kclsdev/scripts/00_01_prep/Structure --finished-dir /home/kclsdev/scripts/00_01_prep/Structure/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
perl update_driver.pl --dir /home/kclsdev/scripts/00_01_prep --finished-dir /home/kclsdev/scripts/00_01_prep/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 01_asset 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/01_asset --finished-dir /home/kclsdev/scripts/01_asset/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --max-processes 2 --exit-on-error
echo 01_action 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/01_action --finished-dir /home/kclsdev/scripts/01_action/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --max-processes 4 --exit-on-error

echo 02 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/02_record_entry_one --finished-dir /home/kclsdev/scripts/02_record_entry_one/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 03 
date
perl update_driver.pl --dir /home/kclsdev/scripts/03_record_entry_two/before --finished-dir /home/kclsdev/scripts/03_record_entry_two/before/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
perl data_update_driver.pl --dir /home/kclsdev/scripts/03_record_entry_two --finished-dir /home/kclsdev/scripts/03_record_entry_two/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
perl update_driver.pl --dir /home/kclsdev/scripts/03_record_entry_two/after --finished-dir /home/kclsdev/scripts/03_record_entry_two/after/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 04 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/04_record_entry_three --finished-dir /home/kclsdev/scripts/04_record_entry_three/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 05_a 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/05_a_record_entry_four --finished-dir /home/kclsdev/scripts/05_a_record_entry_four/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 05_b 
date
perl update_driver.pl --dir /home/kclsdev/scripts/05_b_record_entry_four/before --finished-dir /home/kclsdev/scripts/05_b_record_entry_four/before/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen 
perl data_update_driver.pl --dir /home/kclsdev/scripts/05_b_record_entry_four --finished-dir /home/kclsdev/scripts/05_b_record_entry_four/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen 
perl update_driver.pl --dir /home/kclsdev/scripts/05_b_record_entry_four/after --finished-dir /home/kclsdev/scripts/05_b_record_entry_four/after/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen 
echo 05_c 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/05_c_record_entry_four --finished-dir /home/kclsdev/scripts/05_c_record_entry_four/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 06 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/06_record_entry_b_maintain --finished-dir /home/kclsdev/scripts/06_record_entry_b_maintain/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen 
echo 07 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/07_record_entry_bbb --finished-dir /home/kclsdev/scripts/07_record_entry_bbb/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 08 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/08_record_entry_c_contains --finished-dir /home/kclsdev/scripts/08_record_entry_c_contains/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 09 
date
perl data_update_driver.pl --dir /home/kclsdev/scripts/09_record_entry_fingerprint --finished-dir /home/kclsdev/scripts/09_record_entry_fingerprint/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
echo 10 
date
perl update_driver.pl --dir /home/kclsdev/scripts/10_rebuild_indexes --finished-dir /home/kclsdev/scripts/10_rebuild_indexes/fin --database evergreen_test --host 192.168.0.215 --user evergreen --password evergreen --exit-on-error
date