from settings import *

def flow_acc_month():
    for i in range(1,13):
        name = str(i).zfill(2)
        arcpy.gp.FlowAccumulation_sa(
            os.path.join(RASTER_DIR,"fdir_area.tif"),
            os.path.join(RASTER_DIR, "facc_{}_min.tif".format(name)),
            os.path.join(RASTER_DIR, "q_area_{}_min.tif".format(name)),
            'FLOAT')
        print(name)

def main():
    flow_acc_month()

# if __name__ == '__main__':
#     main()