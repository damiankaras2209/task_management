# Task Management
Rozwiązanie podzielone zostało na 2 pliki: create.sql tworzący niezbędne obiekty oraz fill.sql uzupełniający dane testowe.

Podział na organizacje został zrealizowany poprzez dodanie tabeli Tenants oraz umieszczenie klucza obcego TenantId w tabelach Users oraz Tasks.
Zakładam, że autentykacja następuje w innej części systemu. W zakresie uprawnień w procedurze edycji zadania zawarłem jedynie sprawdzenie czy osoba edytyjąca jest właścicielem zadania. Udostępnianie zadań innym użytkownikom nie zostało zrealizowane, ale zrobiłbym to poprzez relację wiele do wielu między Tasks a Users, gdzie obecność relacji oznaczałaby dostęp do zadania. Historia zadań została obejmuje tytuł, opis, status oraz priorytet.

Dla zapewnienia sprawnego działania systemu w miarę rosnącej ilości wierszy wprowadziłbym jeszcze partycjonowanie tabeli Tasks po kolulumnie CreatedAt z podziałem na np. miesiące

Dostępne procedury z przykładem użycia:

Wyświelt raport o podwładnych managera o id 16
```
EXEC sp_GetTaskStatistics @ManagerId = 16;
```

W podobny sposób można zrealizować wyświetlanie zadań przez użytkownika

Dodaj zadanie
```
EXEC sp_AddTask
@TenantID = 1,
@OwnerID = 27,
@Header = 'Task testowy',
@Priority = 1,
@Status = 1,
@Description = 'Opis';
```

Edycja zadania
```
EXEC sp_UpdateTask
@TaskId = 2,
@Header = 'Task zmieniony',
@Priority = 1,
@Status = 1,
@Description = 'Opis zmieniony',
@ChangedBy = 2;
```
