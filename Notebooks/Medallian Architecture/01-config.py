# Databricks notebook source
class Config():    
    def __init__(self):      
        self.base_dir = spark.sql("describe external location `health_data_landing_zone`").select("url").collect()[0][0]
        self.base_dir_data = f"{self.base_dir}data"
        self.base_dir_checkpoint = f"{self.base_dir}checkpoints"
        self.db_name = "sbit_db"
        self.maxFilesPerTrigger = 1000


if __name__ == "__main__":
    conf = Config()
    print(conf.base_dir_data)
    print(conf.base_dir_checkpoint)
