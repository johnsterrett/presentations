cd "C:\Program Files (x86)\Microsoft Corporation\Database Experimentation Assistant\Dependencies\X64"
ostress -E -Ssql2022.local -dContosoRetailDW -i"C:\demos\Perf-PreCon\IntroPerformanceTuning\block\*.sql" -r10 -n10