(import (scheme base)
        (scheme char)
        (scheme file)
        (scheme write)
        (srfi 28))

(define-record-type scheme
  (make-scheme name host
               user repo
               git-ref/head
               git-ref/release
               filename contents)
  scheme?
  (name scheme-name)
  (host scheme-host)
  (user scheme-user)
  ;; TODO: Add Bitbucket and Savannah support
  (repo scheme-repo)
  (git-ref/head scheme-git-ref/head)
  (git-ref/release scheme-git-ref/release)
  (filename scheme-filename)
  (contents scheme-contents))

(define schemes
  (list
   (make-scheme "bigloo" "github"
                "manuel-serrano" "bigloo"
                "master" "4.3h"
                "manuals/srfi.texi" "^@item @code{srfi-[0-9]+} ")

   (make-scheme "chibi" "github"
                "ashinn" "chibi-scheme"
                "master" "0.9.1"
                "lib/srfi/[0-9]+.sld" #f)

   ;; (make-scheme "gambit" "github"
   ;;              "gambit" "gambit"
   ;;              "master" "v4.9.3"
   ;;              "lib/srfi/[0-9]+" #f)

   (make-scheme "gauche" "github"
                "shirok" "Gauche"
                "master" "release0_9_9"
                "src/srfis.scm" "^srfi-[0-9]+")

   (make-scheme "gerbil" "github"
                "vyzo" "gerbil"
                "master" "v0.16"
                "doc/guide/srfi.md" "\\[SRFI +[0-9]+\\]")

   (make-scheme "kawa" "gitlab"
                "kashell" "Kawa"
                "master" "3.1.1"
                "doc/kawa.texi" "^@uref{http://srfi.schemers.org/srfi-[0-9]+.*, ?SRFI[ -][0-9]+}:")

   (make-scheme "loko" "gitlab"
                "weinholt" "loko"
                "master" "v0.6.0"
                "Documentation/manual/lib-std.texi" "^@code{\\(srfi :[0-9]+ ")

   (make-scheme "sagittarius" "github"
                "ktakashi" "sagittarius-scheme"
                "master" "version_0.9.7"
                "doc/srfi.scrbl" "\\(srfi :[0-9]+[ )]")

   (make-scheme "racket" "github"
                "racket" "srfi"
                "master" "v7.9"
                "srfi-lib/srfi/%3a[0-9]+.rkt" #f)

   (make-scheme "stklos" "github"
                "egallesio" "STklos"
                "master" "stklos-1.50"
                "doc/skb/srfi.stk" "^ +.?\\(?\\([0-9]+ +\\. \"")

   (make-scheme "unsyntax" "gitlab"
                "nieper" "unsyntax"
                "master" "v0.0.3"
                "src/srfi/[0-9]+.s.?.?" #f)

   (make-scheme "vicare" "github"
                "marcomaggi" "vicare"
                "master" "v0.4d1.2"
                "doc/srfi.texi" "@ansrfi{[0-9]+}")

   ))

(define (displayln x) (display x) (newline))

(define (shell-pipeline commands)
  (write-string (car commands))
  (for-each (lambda (command)
              (display " |\n\t")
              (display command))
            (cdr commands))
  (newline))

(define (scheme-archive-url scm git-ref)
  (apply format "https://~a.com/~a/~a/~a/~a.tar.gz"
         (scheme-host scm)
         (scheme-user scm)
         (scheme-repo scm)
         (cond
          ((or (string=? (scheme-host scm) "github"))
           (list "archive"
                 git-ref))
          ((string=? (scheme-host scm) "gitlab")
           (list "-/archive"
                 (if (string=? git-ref (scheme-git-ref/head scm))
                     git-ref
                     (string-append git-ref "/" (scheme-name scm) "-" git-ref)))))))

(define (scheme-archive-filename scm git-ref)
  (define archive-filename
    ;; HACK: GitHub archives strip the #\v in the dirname in archive
    (if (and (>= (string-length git-ref) 2)
             (string=? (scheme-host scm) "github")
             (char=? #\v (string-ref git-ref 0))
             (char-numeric? (string-ref git-ref 1)))
        (substring git-ref 1 (string-length git-ref))
        git-ref))
  (format "~a-~a/~a"
          (scheme-repo scm)
          ;; HACK: Workaround for GitLab's wonky "add hash to dirname" quirk
          (if (string=? (scheme-host scm) "gitlab")
              (string-append archive-filename
                             (if (scheme-contents scm) "*" ".*"))
              archive-filename)
          (scheme-filename scm)))

(define (write-listing scm git-ref suffix)
  (define name (string-append (scheme-name scm) suffix))
  (with-output-to-file
      (string-append "listings/" name ".sh")
    (lambda ()
      (displayln "#!/bin/bash")
      (displayln "# Auto-generated by listings.scm")
      (displayln "set -eu -o pipefail")
      (displayln "cd \"$(dirname \"$0\")\"")
      (shell-pipeline
       (if (not git-ref)
           (list
            (string-append "printf '' >" name ".scm"))
           (append
            (list
             (string-append
              "curl --fail --silent --show-error --location \\\n\t"
              (scheme-archive-url scm git-ref))
             "gunzip")
            (if (not (scheme-contents scm))
                (list "${TAR:-tar} -tf -"
                      (string-append
                       "grep -oE '"
                       (scheme-archive-filename scm git-ref) "'")
                      "sed 's@%3a@@'")
                (list (string-append
                       "${TAR:-tar} -xf - --to-stdout --wildcards '"
                       (scheme-archive-filename scm git-ref) "'")
                      (string-append
                       "grep -oE '"
                       (scheme-contents scm) "'")))
            (list
             "grep -oE '[0-9]+'"
             "sort -g"
             (string-append "uniq > ../data/" name ".scm"))))))))

(for-each (lambda (scm)
            (write-listing scm (scheme-git-ref/head scm) "-head")
            (write-listing scm (scheme-git-ref/release scm) ""))
          schemes)
