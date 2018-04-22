(var whitelist ["localhost.localdomain"])
(local dnsmasq "./dnsmasq.conf")
(local unbound "./unbound.conf")

(local lib (require "lib"))
(local (file exec table fmt string func) (values (. lib "file")
                                                 (. lib "exec")
                                                 (. lib "table")
                                                 (. lib "fmt")
                                                 (. lib "string")
                                                 (. lib "func")))
(local (ipairs curl cmd printf warnf) (values ipairs
                                              (exec.ctx "curl")
                                              exec.cmd
                                              fmt.print
                                              fmt.warn))
(set whitelist (table.to_hash whitelist))
(local try (func.try fmt.panic))

(local start (fn [src]
  (printf "[*] Fetching from %s...\n" src)))

(local add-to (fn [hosts]
  (fn [exit tbl src pattern bool]
    (try exit (.. "[!] Failed fetching from " src " .\n"))
    (local tn (# tbl.stdout))
    (if (> tn 0)
      (do
        (printf "[+] Got %d hosts.\n" tn)
        (each [_ h (ipairs tbl.stdout)]
          (local s (string.match h, pattern, bool))
          (when (and s
                     (string.find s "." 1 true)
                     (not (. whitelist s)))
            (tset hosts s true))))
      (warnf "[!] No hosts returned from %s.\n" src)))))
(var hosts {})
(local add-to-hosts (add-to hosts))
(global _ENV nil)

(var src-url "http://pgl.yoyo.org/adservers/serverlist.php")
(start src-url)
(var (exit output)
  (cmd.curl ["-s"
             "-d"
             "mimetype=plaintext"
             "-d"
             "hostformat=unixhosts"
             src-url]))
(add-to-hosts exit output src-url "[%S]*")

(set src-url "http://winhelp2002.mvps.org/hosts.txt")
(start src-url)
(set (exit output) (curl "-s" src-url))
(add-to-hosts exit output src-url "0.0.0.0%s+([%S]*)")

(do
  ;; The following URLs return hosts in the format:
  ;; 127.0.0.1 ad.example.com
  (local urls ["https://adaway.org/hosts.txt"
               "http://www.malwaredomainlist.com/hostslist/hosts.txt"
               "http://hosts-file.net/.%5Cad_servers.txt"
               "http://someonewhocares.org/hosts/hosts"])
  (each [_ u (ipairs urls)]
    (start u)
    (set (exit output) (curl "-s" u))
    (add-to-hosts exit output u "127.0.0.1%s+([%S]*)")))

(set hosts (table.to_seq hosts))
(printf "[+] %d hosts generated.\n" (# hosts))

;;; We do not care if the target files are nonexistent so ignore return values.
(printf "[*] Truncating %s.\n" dnsmasq)
(file.truncate dnsmasq)
(printf "[*] Truncating %s.\n" unbound)
(file.truncate unbound)

(printf "[+] Writing to %s.\n" dnsmasq)
(printf "[+] Writing to %s.\n" unbound)
(each [_ h (ipairs hosts)]
  (local H (string.gsub h '"' ''))
  (when (not (file.write dnsmasq (.. "0.0.0.0 " H "\n") "a+"))
    (warnf "[!] Failed writing to %s.\n" dnsmasq))
  (when (not (file.write unbound (.. 'local-data: "' H ' A 0.0.0.0"\n') "a+"))
    (warnf "[!] Failed writing to %s.\n" unbound)))

(fmt.print "[+] Finished.\n")
