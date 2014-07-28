(load "evalo.scm")
(load "test-check.scm")

(test "eval-find-smallesto term  I love you 1"
  ;; conda-based loop
  (run* (q)
    (fresh (term size)
      (== (list term size) q)
      (eval-find-smallesto term '(I love you) size)))
  '(('(I love you) (s z))))

(test "eval-find-smallesto  find all of the smallest '(I love you)-building terms that are at least size 2 or greater"
  ;; conda-based loop
  (run* (q)
    (fresh (term size rest)
      (== `(s s . ,rest) size)
      (eval-find-smallesto term '(I love you) size)
      (== (list term size) q)))
  '(((cons 'I '(love you))
     (s s s z))))

(test "eval-find-smallesto  find all of the smallest '(I love you)-building terms that are at least size 4 or greater"
  ;; conda-based loop
  (run* (q)
    (fresh (term size rest)
      (== `(s s s s . ,rest) size)
      (eval-find-smallesto term '(I love you) size)
      (== (list term size) q)))
  '(((((lambda (_.0) '(I love you)) '_.1)
      (s s s s z))
     (=/= ((_.0 closure)) ((_.0 quote))) (sym _.0)
     (absento (closure _.1)))
    ((((lambda (_.0) _.0) '(I love you))
      (s s s s z))
     (=/= ((_.0 closure))) (sym _.0))
    ((((lambda (_.0) '(I love you)) (lambda (_.1) _.2))
      (s s s s z))
     (=/= ((_.0 closure)) ((_.0 quote)) ((_.1 closure)))
     (sym _.0 _.1) (absento (closure _.2)))))

;; Finds one quine of the smallest possible term size (there could be
;; others of that size, although it turns out there are not, as can be
;; proved by changing the run 1 to a run*)
;;
;; Testing "eval-find-smallesto term   quine 1"
;; running stats for (run 1 (q) (fresh (term size) (== (list term size) q) (eval-find-smallesto term term size))):
;;     634 collections
;;     50227 ms elapsed cpu time, including 1265 ms collecting
;;     50262 ms elapsed real time, including 1269 ms collecting
;;     5305968784 bytes allocated
(test "eval-find-smallesto term   quine 1"
  ;; conda-based loop
  (time (run 1 (q)
          (fresh (term size)
            (== (list term size) q)
            (eval-find-smallesto term term size))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote)))
     (sym _.0))))

;; Finds the smallest quine, and proves it is the only quine of that size or smaller.
;;
;; Testing "eval-find-smallesto term   all smallest quines 1"
;; running stats for (run* (q) (fresh (term size) (== (list term size) q) (eval-find-smallesto term term size))):
;;     2257 collections
;;     202225 ms elapsed cpu time, including 5448 ms collecting
;;     202328 ms elapsed real time, including 5459 ms collecting
;;     18913076288 bytes allocated
(test "eval-find-smallesto term   all smallest quines 1"
  ;; conda-based loop
  (time (run* (q)
          (fresh (term size)
            (== (list term size) q)
            (eval-find-smallesto term term size))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote)))
     (sym _.0))))

;; Testing "quine-increment-size-1"
;; running stats for (run 1 (out) (fresh (term size) (eval-increment-sizeo term term size) (== (list term size) out))):
;;     61 collections
;;     4502 ms elapsed cpu time, including 253 ms collecting
;;     4504 ms elapsed real time, including 253 ms collecting
;;     510730928 bytes allocated
(test "quine-increment-size-1"
  ;; conde-based loop
  (time (run 1 (out) (fresh (term size) (eval-increment-sizeo term term size) (== (list term size) out))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0))))

(test "eval-increment-sizeo term  I love you 1"
  ;; conde-based loop
  (run 10 (term)
    (fresh (size)
      (eval-increment-sizeo term '(I love you) size)))
  '('(I love you)
    (cons 'I '(love you))
    (((lambda (_.0) '(I love you)) '_.1)
     (=/= ((_.0 closure)) ((_.0 quote))) (sym _.0) (absento (closure _.1)))
    (((lambda (_.0) _.0) '(I love you))
     (=/= ((_.0 closure))) (sym _.0))
    (((lambda (_.0) '(I love you)) (lambda (_.1) _.2))
     (=/= ((_.0 closure)) ((_.0 quote)) ((_.1 closure))) (sym _.0 _.1) (absento (closure _.2)))
    (cons 'I (cons 'love '(you)))
    ((cons ((lambda (_.0) 'I) '_.1) '(love you))
     (=/= ((_.0 closure)) ((_.0 quote))) (sym _.0) (absento (closure _.1)))
    (((lambda (_.0) (cons 'I '(love you))) '_.1)
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0) (absento (closure _.1)))
    ((cons ((lambda (_.0) _.0) 'I) '(love you))
     (=/= ((_.0 closure))) (sym _.0))
    ((cons 'I ((lambda (_.0) '(love you)) '_.1))
     (=/= ((_.0 closure)) ((_.0 quote))) (sym _.0) (absento (closure _.1)))))

;; shows that the generated terms do not increase in size
;; monotonically when using the conde-based 'eval-increment-sizeo'
(test "eval-increment-sizeo term  I love you 2"
  ;; conde-based loop  
  (map peano->arabic
       (run 100 (size)
         (fresh (term)
           (eval-increment-sizeo term '(I love you) size))))
  '(1 3 4 4 4 5 6 6 6 6 6 6 6 6 6 6 6 6 7 6 7 7 6 7 7 6 8 7 7 7 7 7 7 8 7 8 8 7 7 8 7 8 7 7 7 8 8 7 7 8 8 7 7 7 7 8 9 8 7 7 8 8 8 7 8 9 7 7 7 8 7 7 7 8 8 8 7 7 7 8 8 7 8 9 9 9 8 9 9 9 8 9 8 9 9 9 9 9 9 9))

;; Testing "quine-1"
;; running stats for (run 1 (out) (fresh (exp start) (== (list exp start) out) (evalo exp exp start))):
;;     2 collections
;;     210 ms elapsed cpu time, including 4 ms collecting
;;     210 ms elapsed real time, including 4 ms collecting
;;     20824128 bytes allocated
(test "quine-1"
  (time
    (run 1 (out)
      (fresh (exp start)
        (== (list exp start) out)
        (evalo exp exp start))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0))))

(test "quine-1-correct-size-specified"
  (time
    (run 1 (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s s s s z) start)
        (evalo exp exp start))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0))))

;; proof!
(test "quine-1-incorrect-tiny-size-specified-0"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-1"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-2"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-3"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-4"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-5"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-6"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-7"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-8"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-9"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
(test "quine-1-incorrect-tiny-size-specified-10"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
;;
;; prove there is no quine of size 11
(test "quine-1-incorrect-tiny-size-specified-11"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s s s z) start)
        (evalo exp exp start))))
  '())

;; just find one
(test "quine-1-any-quine-size-12"
  (time
    (run 1 (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s s s s z) start)
        (evalo exp exp start))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0))))

;; proof!
;;
;; (takes a little over 2 minutes to prove there is only one quine of
;; size 12)
;;
;; could parallelize these queries; would this help?
;;
;; are we benefiting from pruning/fail-fast behavior, in constrast to
;; naive generate & test?  I suspect so.  Prove it!
(test "quine-1-all-quines-size-12"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s s s s z) start)
        (evalo exp exp start))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0))))



(test "twine-1"
  (time
   (run 1 (out)
     (fresh (p q p-start q-start)
       (== (list p q p-start q-start) out)
       (=/= p q)
       (evalo p q p-start)
       (evalo q p q-start))))
  '((('((lambda (_.0) (cons 'quote (cons (cons _.0 (cons (cons 'quote (cons _.0 '())) '())) '()))) '(lambda (_.0) (cons 'quote (cons (cons _.0 (cons (cons 'quote (cons _.0 '())) '())) '()))))
      ((lambda (_.0) (cons 'quote (cons (cons _.0 (cons (cons 'quote (cons _.0 '())) '())) '()))) '(lambda (_.0) (cons 'quote (cons (cons _.0 (cons (cons 'quote (cons _.0 '())) '())) '()))))
      (s z)
      (s s s s s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0))))
