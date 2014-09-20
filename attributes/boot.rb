default_unless[:sys][:boot][:grubdefault] = "0"
default_unless[:sys][:boot][:params] = Array.new
default_unless[:sys][:boot][:config] = Hash.new
default_unless[:sys][:boot][:trigger_reboot] = :immediately
