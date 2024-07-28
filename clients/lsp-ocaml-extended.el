;;; lsp-ocaml-extended.el --- OCaml support for lsp-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Tim McGilchrist <timmcgil@gmail.com>

;; Author: Tim McGilchrist <timmcgil@gmail.com>
;; Keywords: lsp, ocaml

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Support for OCaml specific extensions to LSP

;;; Code:

(require 'lsp-mode)
(require 'lsp-ocaml)
(require 'dash)
(require 'ht)
(require 'lsp-semantic-tokens)
(require 's)

;; ---------------------------------------------------------------------
;; Configuration

(defgroup lsp-ocaml-extended nil
  "Customization group for ‘lsp-ocaml-extended’."
  :group 'lsp-ocaml-extended)

;; These correspond to the JSON Request structures passed to ocaml-lsp-server

(lsp-interface (ocamllsp:HoverExtendedParams (:textDocument :position :verbosity))
               (ocamllsp:TypeEnclosingParams (:uri :at :index :verbosity) (:enclosings :index :type))
               (ocamllsp:TypedHoleParams (:uri))
               (ocamllsp:WrappingAstNode (:uri :position)))

(defun lsp-ocaml-open-dune-project (&optional new-window)
  "Open the closest dune-project from the current file.

If NEW-WINDOW (interactively the prefix argument) is non-nil,
open in a new window."

  (interactive "P")
  (let* ((workspace (lsp-find-workspace 'ocaml-lsp-server (buffer-file-name))))
    ;; TODO Should check existence of the file before opening a buffer for it.
    ;;      Is there a safer way to append file paths?
    (let ((dune-project-path (concat (lsp-workspace-root) "/dune-project")))
      (funcall (if new-window #'find-file-other-window #'find-file)
               dune-project-path))))

(defun lsp-ocaml-hover-extended ()
  "Alternative hover command providing additional information."
  (interactive)
  (-let* ((params (lsp-make-ocamllsp-hover-extended-params
                   :text-document (lsp--text-document-identifier)
                   :position (lsp--cur-position)
                   :verbosity nil))
          (results (lsp-send-request (lsp-make-request "ocamllsp/hoverExtended" params))))
    (lsp-log "ocamllsp/hoverExtended Results: '%s'" results)))

(defun lsp-ocaml-wrapping-ast-node ()
  "Return the range of the typed AST node enclosing the cursor."
  (interactive)
  (-let* ((params (lsp-make-ocamllsp-wrapping-ast-node
                   :uri (lsp--buffer-uri)
                   :position (lsp--cur-position)))
          (results (lsp-send-request (lsp-make-request "ocamllsp/wrappingAstNode" params))))
    (lsp-log "ocamllsp/wrappingAstNode Results: '%s'" results)))

(defun lsp-ocaml-typed-hole ()
  "Request typed holes in current file."
  (interactive)
  (-let* ((params (lsp-make-ocamllsp-typed-hole-params
                   :uri (lsp--buffer-uri)))
          (results (lsp-send-request (lsp-make-request "ocamllsp/typedHoles" params))))
    (lsp-log "ocamllsp/typedHoles Results: '%s'" results)))

(defun lsp-ocaml-infer-intf ()
  "Infer module interface for current file."
  (interactive)
  (-let* ((params (lsp--buffer-uri))
          (results (lsp-send-request (lsp-make-request "ocamllsp/inferIntf" params))))
    (lsp-log "ocamllsp/inferIntf Results: '%s'" results)))

(defun lsp-ocaml-switch-impl-intf ()
  "Get the type enclosing under the cursor and then its surrounding enclosings."
  (interactive)
  (-let* ((params (lsp--buffer-uri))
          (results (lsp-send-request (lsp-make-request "ocamllsp/switchImplIntf" params))))
    (lsp-log "ocamllsp/switchImplIntf Results: '%s'" results)))

(defun lsp-ocaml-type-enclosing ()
  "Get the type enclosing under the cursor and then its surrounding enclosings."
  (interactive)
  (-let* ((params (lsp-make-ocamllsp-type-enclosing-params
                   :uri (lsp--buffer-uri)
                   :at (lsp--cur-position)
                   :index 0             ; TODO Hardcoded values for now, what should they be?
                   :verbosity 1))
          (results (lsp-send-request (lsp-make-request "ocamllsp/typeEnclosing" params))))
    (lsp-log "ocamllsp/typeEnclosing Results: '%s'" results)))

(defun lsp-ocaml-merlin-call ()
  "Get the type enclosing under the cursor and then its surrounding enclosings."
  (interactive)
  (-let* ((params (lsp--buffer-uri))
          (results (lsp-send-request (lsp-make-request "ocamllsp/merlinCallCompatible" params))))
    (lsp-log "ocamllsp/merlinCallCompatible Results: '%s'" results)))

(provide 'lsp-ocaml-extended)
;;; lsp-ocaml.el ends here
