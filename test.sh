cantidad_archivos_entrada=$(ls -1q test/entrada* | wc -l)
test_fallidos=0
test_pasados=0

for i in `seq 1 $cantidad_archivos_entrada`
do
        path_entrada='test/entrada'$i
        path_esperada='test/esperada'$i

	res=$(cat "$path_entrada" | ./tp1 | diff "$path_esperada" -)
        if [[ $res ]];
        then
                echo "Test $i: ERROR"
                echo $res
                test_fallidos=$((test_fallidos+1))
        else
                echo "Test $i:OK"
                test_pasados=$((test_pasados+1))
        fi
done

echo 'TESTS CON ARCHIVO DE ENTRADA: Pasados' $test_pasados 'tests de' $cantidad_archivos_entrada

test_fallidos=0
test_pasados=0

for i in `seq 1 $cantidad_archivos_entrada`
do
        path_entrada='test/entrada'$i
        path_esperada='test/esperada'$i

	res=$(cat "$path_entrada" | ./tp1 | diff "$path_esperada" -)
        if [[ $res ]];
        then
                echo "Test $i: ERROR"
                echo $res
                test_fallidos=$((test_fallidos+1))
        else
                echo "Test $i:OK"
                test_pasados=$((test_pasados+1))
        fi
done

echo 'TESTS CON STDIN DE ENTRADA: Pasados' $test_pasados 'tests de' $cantidad_archivos_entrada
