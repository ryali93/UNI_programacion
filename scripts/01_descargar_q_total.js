var pisco = ee.Image("users/ryali93/rgee_upload/pisco_area");
var ra_cn_ch_max = ee.Image("users/ryali93/rgee_upload/ra_cn_ch_max");
var geometry = ee.FeatureCollection("users/ryali93/gpo_area_uni");
var ra_cn_ch_min = ee.Image("users/ryali93/rgee_upload/ra_cn_ch_min");
var ra_cn_cn_max = ee.Image("users/ryali93/rgee_upload/ra_cn_cn_max");
var ra_cn_cn_min = ee.Image("users/ryali93/rgee_upload/ra_cn_cn_min");
var ra_cn_cs_max = ee.Image("users/ryali93/rgee_upload/ra_cn_cs_max");
var ra_cn_cs_min = ee.Image("users/ryali93/rgee_upload/ra_cn_cs_min");

var pisco_100 = pisco.resample('bilinear').reproject({crs: 'EPSG:32718', scale:100});
var lista_bandas = pisco_100.bandNames();

var bandas_01 = ee.List.sequence(0, 431, 12);
var bandas_02 = ee.List.sequence(1, 432, 12);
var bandas_03 = ee.List.sequence(2, 432, 12);
var bandas_04 = ee.List.sequence(3, 432, 12);
var bandas_05 = ee.List.sequence(4, 432, 12);
var bandas_06 = ee.List.sequence(5, 432, 12);
var bandas_07 = ee.List.sequence(6, 432, 12);
var bandas_08 = ee.List.sequence(7, 432, 12);
var bandas_09 = ee.List.sequence(8, 432, 12);
var bandas_10 = ee.List.sequence(9, 432, 12);
var bandas_11 = ee.List.sequence(10, 432, 12);
var bandas_12 = ee.List.sequence(11, 432, 12);


var q_mes = function(m){
    var banda = ee.String(lista_bandas.get(m));
    var PP = pisco_100.select(banda);
    var S = ee.Image(ee.Number(25400)).divide(ra_cn_cs_min.select('b1')).subtract(ee.Number(254));
    var IA = ee.Image(ee.Number(0.2)).multiply(S);
    var Q = ((PP.subtract(IA)).pow(2)).divide(PP.subtract(IA).add(S));
    var Q2 = Q.multiply(10000).divide(ee.Number(2592000000));
    var rename = Q2.select(banda).rename(ee.String('banda'));
    return(rename);
  }

var q_01 = ee.ImageCollection.fromImages(bandas_01.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_02 = ee.ImageCollection.fromImages(bandas_02.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_03 = ee.ImageCollection.fromImages(bandas_03.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_04 = ee.ImageCollection.fromImages(bandas_04.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_05 = ee.ImageCollection.fromImages(bandas_05.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_06 = ee.ImageCollection.fromImages(bandas_06.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_07 = ee.ImageCollection.fromImages(bandas_07.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_08 = ee.ImageCollection.fromImages(bandas_08.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_09 = ee.ImageCollection.fromImages(bandas_09.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_10 = ee.ImageCollection.fromImages(bandas_10.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_11 = ee.ImageCollection.fromImages(bandas_11.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});
var q_12 = ee.ImageCollection.fromImages(bandas_12.map(q_mes)).mean().reproject({crs: 'EPSG:32718', scale:100});


Export.image.toDrive({image: q_01, description: 'q_01', scale: 100, region: geometry});
Export.image.toDrive({image: q_02, description: 'q_02', scale: 100, region: geometry});
Export.image.toDrive({image: q_03, description: 'q_03', scale: 100, region: geometry});
Export.image.toDrive({image: q_04, description: 'q_04', scale: 100, region: geometry});
Export.image.toDrive({image: q_05, description: 'q_05', scale: 100, region: geometry});
Export.image.toDrive({image: q_06, description: 'q_06', scale: 100, region: geometry});
Export.image.toDrive({image: q_07, description: 'q_07', scale: 100, region: geometry});
Export.image.toDrive({image: q_08, description: 'q_08', scale: 100, region: geometry});
Export.image.toDrive({image: q_09, description: 'q_09', scale: 100, region: geometry});
Export.image.toDrive({image: q_10, description: 'q_10', scale: 100, region: geometry});
Export.image.toDrive({image: q_11, description: 'q_11', scale: 100, region: geometry})
Export.image.toDrive({image: q_12, description: 'q_12', scale: 100, region: geometry})