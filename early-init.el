(setq package-enable-at-startup nil)
;; Only run GC when memory usage exceeds or is equal to 60MiB
(setq gc-cons-threshold (* 1024 1024 60)) 
(setq read-process-output-max (* 1024 1024))
(setenv "LSP_USE_PLISTS" "true")
(setq lsp-use-plists t)
