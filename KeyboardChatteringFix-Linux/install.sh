# 1. install the requirement globally
# 2. test with `python3 -m src`
# 3. find the keyboard id (it could end with kde)
# 4. setup the bashscript and the service
# 5. for more details see my fork at 
#
# http://github.com/ayoubelouardi/KeybardChatteringFix-Linux.git
#
sudo mv chattering_fix.service /etc/systemd/system/chattering_fix.service
systemctl enable --now chattering_fix
systemctl status chattering_fix.service
journalctl -xeu chattering_fix.service
