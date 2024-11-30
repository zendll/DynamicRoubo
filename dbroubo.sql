CREATE TABLE IF NOT EXISTS locais_roubo (
    ID INT AUTO_INCREMENT PRIMARY KEY,         
    Nome VARCHAR(20) NOT NULL,               
    Dinheiro INT NOT NULL,             
    PosX FLOAT NOT NULL,                        
    PosY FLOAT NOT NULL,                        
    PosZ FLOAT NOT NULL,                       
    Interior INT NOT NULL,                        
    World INT NOT NULL,
    DataCriacao VARCHAR(20),
    TotalRoubos INT NOT NULL                           
);