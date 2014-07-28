(load "evalo.scm")
(load "test-check.scm")

(test "quine-1"
  (time (run 1 (q) (evalo q q)))
  '((((lambda (_.0) (list _.0 (list 'quote _.0)))
      '(lambda (_.0) (list _.0 (list 'quote _.0))))
     (=/= ((_.0 closure)) ((_.0 list)) ((_.0 quote)))
     (sym _.0))))

(test "twine-1"
  (time (run 1 (out)
          (fresh (p q)
            (== (list p q) out)
            (=/= p q)
            (evalo p q)
            (evalo q p))))
  '((('((lambda (_.0) (list 'quote (list _.0 (list 'quote _.0)))) '(lambda (_.0) (list 'quote (list _.0 (list 'quote _.0)))))
      ((lambda (_.0) (list 'quote (list _.0 (list 'quote _.0)))) '(lambda (_.0) (list 'quote (list _.0 (list 'quote _.0))))))
     (=/= ((_.0 closure)) ((_.0 list)) ((_.0 quote))) (sym _.0))))

(test "thrine-1"
  (time (run 1 (out)
          (fresh (p q r)
            (== (list p q r) out)
            (=/= p q)
            (=/= p r)
            (=/= q r)
            (evalo p q)
            (evalo q r)
            (evalo r p))))
  '(((''((lambda (_.0) (list 'quote (list 'quote (list _.0 (list 'quote _.0))))) '(lambda (_.0) (list 'quote (list 'quote (list _.0 (list 'quote _.0))))))
      '((lambda (_.0) (list 'quote (list 'quote (list _.0 (list 'quote _.0))))) '(lambda (_.0) (list 'quote (list 'quote (list _.0 (list 'quote _.0))))))
      ((lambda (_.0) (list 'quote (list 'quote (list _.0 (list 'quote _.0))))) '(lambda (_.0) (list 'quote (list 'quote (list _.0 (list 'quote _.0)))))))
     (=/= ((_.0 closure)) ((_.0 list)) ((_.0 quote))) (sym _.0))))