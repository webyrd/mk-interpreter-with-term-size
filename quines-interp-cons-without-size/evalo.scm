(load "mk.scm")

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

(define evalo
  (lambda (exp val)
    (fresh ()
      (absento 'closure exp)
      (eval-expo exp '() val))))

(define eval-expo
  (lambda (exp env val)
    (conde
      ((fresh (v)
         (== `(quote ,v) exp)
         (== v val)
         (not-in-envo 'quote env)
         (absento 'closure v)))
      ((fresh (e1 e2 v1 v2)
         (== `(cons ,e1 ,e2) exp)
         (== (cons v1 v2) val)
         (not-in-envo 'cons env)
         (absento 'closure e1)
         (absento 'closure e2)
         (eval-expo e1 env v1)
         (eval-expo e2 env v2)))
      ((symbolo exp) (lookupo exp env val))
      ((fresh (rator rand x body env^ a)
         (== `(,rator ,rand) exp)
         (eval-expo rator env `(closure ,x ,body ,env^))
         (eval-expo rand env a)
         (eval-expo body `((,x . ,a) . ,env^) val)))
      ((fresh (x body)
         (== `(lambda (,x) ,body) exp)
         (== `(closure ,x ,body ,env) val)
         (symbolo x)
         (not-in-envo 'lambda env))))))
