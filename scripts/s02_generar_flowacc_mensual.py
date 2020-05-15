from settings import *

DEM = os.path.join(RASTER_DIR, "ra_dem.tif")

def flow_acc_month():
    fill_dem = arcpy.gp.Fill_sa(DEM, "in_memory\\fill_dem", '#')
    flow_dir = arcpy.gp.FlowDirection_sa(fill_dem, "in_memory\\flow_dir", 'NORMAL', '#')
    contour = arcpy.gp.Contour_sa(fill_dem, os.path.join(SHP_DIR, "gpl_curvas.shp"), '50', '0', '1')
    for i in range(1,433):
        name = str(i).zfill(3)
        arcpy.gp.FlowAccumulation_sa(
            flow_dir,
            os.path.join(RASTER_DIR, "facc_{}.tif".format(name)),
            os.path.join(RASTER_DIR, "q_{}.tif".format(name)),
            'FLOAT')
        print(name)


def main():
    flow_acc_month()

# if __name__ == '__main__':
#     main()
