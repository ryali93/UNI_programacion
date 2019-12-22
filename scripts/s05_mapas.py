# from settings import *
import pandas as pd

TABLA = r'E:\2019\UNI\xlsx\tb_second.xls'

def filter_ideval(tabla, desnivel, umbral):
    df = pd.read_excel(tabla)
    df = df[(df["Z_DELTA"] > desnivel) & (df["Q_08"] > umbral)]
    print(list(df["ID_EVAL"]))
    return list(df["ID_EVAL"])


def main():
    filter_ideval(TABLA, 50, 10)

if __name__ == '__main__':
    main()