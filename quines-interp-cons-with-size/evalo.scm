(load "mk.scm")

(define peano->arabic
  (lambda (n)
    (unless (and (list? n) (not (null? n)))
      (error 'peano->arabic "must be given a non-empty list"))
    (sub1 (length n))))


(define lookupo
  (lambda (x env t)
    (fresh (y v rest)
      (== `((,y . ,v) . ,rest) env)
      (conde
        ((== y x) (== v t))
        ((=/= y x) (lookupo x rest t))))))

(define not-in-envo
  (lambda (x env)
    (conde
      ((== '() env))
      ((fresh (y v rest)
         (== `((,y . ,v) . ,rest) env)
         (=/= y x)
         (not-in-envo x rest))))))

(define eval-increment-sizeo
  (lambda (exp val size)
    (let loop ((sz '(z)))
      (conde
        ((== sz size) (evalo exp val sz))
        ((loop (cons 's sz)))))))

;; uses impure control construct to find terms of the smallest size
;; that satisfies the query
(define eval-find-smallesto
  (lambda (exp val size)
    (let loop ((sz '(z)))
      (conda
        ((fresh () (== sz size) (evalo exp val sz)))
        ((loop (cons 's sz)))))))

(define evalo
  (lambda (exp val size-start)
    (fresh ()
      (absento 'closure exp)
      (eval-expo exp '() val size-start '(z)))))

(define eval-expo
  (lambda (exp env val
               ;;
               size-start
               size-left
               ;;
               )
    (conde
      ((fresh (v)
         (== `(quote ,v) exp)
         (== v val)
         ;;
         (== `(s . ,size-left) size-start)
         ;;
         (not-in-envo 'quote env)
         (absento 'closure v)))
      ((fresh (e1 e2 v1 v2 size-start-1 size-left^)
         (== `(cons ,e1 ,e2) exp)
         (== (cons v1 v2) val)
         ;;
         (== `(s . ,size-start-1) size-start)
         ;;
         (not-in-envo 'cons env)
         (absento 'closure e1)
         (absento 'closure e2)
         ;; need better names for these variables!
         (eval-expo e1 env v1 size-start-1 size-left^)
         (eval-expo e2 env v2 size-left^ size-left)))
      ((symbolo exp)
       ;;
       (== `(s . ,size-left) size-start)
       ;;
       (lookupo exp env val))
      ((fresh (rator rand x body env^ a size-start-1 size-left^ size-left^^)
         (== `(,rator ,rand) exp)
         ;;
         (== `(s . ,size-start-1) size-start)
         ;; need better names for these variables!
         (eval-expo rator env `(closure ,x ,body ,env^) size-start-1 size-left^)
         (eval-expo rand env a size-left^ size-left^^)
         (eval-expo body `((,x . ,a) . ,env^) val size-left^^ size-left)))
      ((fresh (x body size-start-1)
         (== `(lambda (,x) ,body) exp)
         (== `(closure ,x ,body ,env) val)
         ;;
         ;; !!! make lambda size 1 !!!!
         ;;
         ;; [do *not* recur into the body of lambda!!!]
         ;;
         (== `(s . ,size-left) size-start)
         ;;
         (symbolo x)
         (not-in-envo 'lambda env))))))

