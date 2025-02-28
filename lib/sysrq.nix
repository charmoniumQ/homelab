{ ... }: {
  boot = {
    kernel = {
      sysctl = {
        # Docs: https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html
        #
        # Use with keyboard (Alt + PrtScr + [key]) or file: echo [key] | sudo tee /proc/sysrq-trigger
        # Keys:
        # (h)elp
        # re(b)oot
        # t(e)rminate-all-tasks
        # k(i)ll-all-tasks
        # (f) oom-kill
        # (j) thaw-filesystems
        # show-(m)emory-usage
        # p(o)weroff
        # (s)ync
        # (u)nmount
        # (r)aw TTY mode
        # (R)eplay dmesg on
        #
        # Helpful mnemonic: (r)eboot (e)ven (i)f (s)ystem (u)tterly (b)orked
        "kernel.sysrq" =
          2    + # enable control of console logging level
          #4   + # enable control of keyboard (SAK, unraw)
          #8   + # enable debugging dumps of processes etc.
          16   + # enable sync command
          32   + # enable remount read-only
          64   + # enable signalling of processes (term, kill, oom-kill)
          128  + # allow reboot/poweroff
          #256 + # allow nicing of all RT tasks
          0;
      };
    };
  };
}
