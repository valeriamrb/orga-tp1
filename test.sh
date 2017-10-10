cantidad_archivos_entrada=$(ls -1q test/entrada* | wc -l)
ibytes_max=10
obytes_max=10


echo '-------------TESTS CON ARCHIVO DE ENTRADA Y VARIACION-------------'
echo '--------------------- DE TAMANIOS DE BUFFER ----------------------'
echo '---------------------- DE ENTRADA Y SALIDA -----------------------'

test_fallidos=0
test_pasados=0

cantidad_tests=$(($ibytes_max * $obytes_max * $cantidad_archivos_entrada))

for i in `seq 1 $cantidad_archivos_entrada`
do
        path_entrada='test/entrada'$i
        path_esperada='test/esperada'$i

	for ibytes in `seq 1 $ibytes_max`
	do
		for obytes in `seq 1 $obytes_max`
		do
			res=$(./tp1 -i $path_entrada -I $ibytes -O $obytes| diff "$path_esperada" -)
		        if [[ $res ]];
		        then
		                echo "Test $i, entrada: $path_entrada, salida: stdout, ibytes = $ibytes, obytes = $obytes: ERROR"
		                echo $res
		                test_fallidos=$((test_fallidos+1))
		        else
		                echo "Test $i, entrada: $path_entrada, salida: stdout, ibytes = $ibytes, obytes = $obytes: OK"
		                test_pasados=$((test_pasados+1))
		        fi
		done
	done
done

echo 'Pasados' $test_pasados 'tests de' $cantidad_tests


echo '---------TESTS CON STDIN DE ENTRADA Y VARIACION---------'
echo '---------------- DE TAMANIOS DE BUFFER -----------------'
echo '----------------- DE ENTRADA Y SALIDA ------------------'

test_fallidos=0
test_pasados=0

cantidad_tests=$(($ibytes_max * $obytes_max * $cantidad_archivos_entrada))

for i in `seq 1 $cantidad_archivos_entrada`
do
        path_entrada='test/entrada'$i
        path_esperada='test/esperada'$i

	for ibytes in `seq 1 $ibytes_max`
	do
		for obytes in `seq 1 $obytes_max`
		do
			res=$(cat "$path_entrada" | ./tp1 -I $ibytes -O $obytes| diff "$path_esperada" -)
		        if [[ $res ]];
		        then
		                echo "Test $i, entrada: stdin, salida: stdout, ibytes = $ibytes, obytes = $obytes: ERROR"
		                echo $res
		                test_fallidos=$((test_fallidos+1))
		        else
		                echo "Test $i, entrada: stdin, salida: stdout, ibytes = $ibytes, obytes = $obytes: OK"
		                test_pasados=$((test_pasados+1))
		        fi
		done
	done
done

echo 'Pasados' $test_pasados 'tests de' $cantidad_tests
