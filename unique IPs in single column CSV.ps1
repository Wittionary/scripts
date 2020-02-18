$CSVfile = "C:\Users\wittionary\Documents\IAS Log Reports\Connects_20200218_095436.csv"
Get-Content $CSVfile | Get-Unique

