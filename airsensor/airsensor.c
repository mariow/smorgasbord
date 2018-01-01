/*
 * airsensor.c
 *
 * Original source: Rodric Yates http://code.google.com/p/airsensor-linux-usb/
 * Modified source: Ap15e (MiOS) http://wiki.micasaverde.com/index.php/CO2_Sensor
 * Modified source: by Sebastian Sjoholm, sebastian.sjoholm@gmail.com
 * This version by: Juergen Plate
 *
 * requirement:
 *   libusb
 *   (sudo apt-get install libusb-dev)
 *
 * compile:
 *   gcc i-Wall -o airsensor airsensor.c -lusb
 */

#include <assert.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <usb.h>
#include <time.h>

/* Device-Handle fuer den Airsensor */
struct usb_dev_handle *devh;

void usage()
  {
  printf("\nAirSensor [options]\n");
  printf("Options:\n");
  printf("-d = Debug-Ausgabe einschalten\n");
  printf("-v = Nur den VOC ausgeben; '0', falls Wert ausserhalb (450..2000)\n");
  printf("-o = Nur einen Wert ausgeben und beenden\n");
  printf("-m = Nur Wert fuer MRTG formatiert ausgeben\n");
  printf("-h = Dieser Hilfe-Text\n\n");
  exit(0);
  }

/* Text und Messwert (falls > 0) mit Datum/Uhrzeit ausgeben */
void printout(char *str, int value)
  {
  time_t t = time(NULL);         /* aktuelle Zeit (Epoche) */
  struct tm tm = *localtime(&t); /* aktuelles Datum/Zeit   */

  printf("%04d-%02d-%02d %02d:%02d:%02d, ", tm.tm_year + 1900, 
         tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
  if (value == 0)
    { printf("%s\n", str); }
  else { printf("%s %d\n", str, value); }
  }

/* USB-Device schliessen, Programm beenden */
void release_usb_device(int dummy)
  {
  int ret;
  ret = usb_release_interface(devh, 0);
  usb_close(devh);
  exit(ret);
  }

/* USB-Device zu Vendor- und Product suchen */
struct usb_device* find_device(int vendor, int product)
  {
  struct usb_bus *bus;
  struct usb_device *dev;

  usb_set_debug(0);
  usb_find_busses();   
  usb_find_devices();
  for (bus = usb_get_busses(); bus; bus = bus->next)
    {
    for (dev = bus->devices; dev; dev = dev->next)
      {
      if (dev->descriptor.idVendor == vendor
          && dev->descriptor.idProduct == product)
        return dev; /* Erfolg: Device zurueckgeben */
      }
    }
  return NULL; /* bei Misserfolg NULL retournieren */
  }

int main(int argc, char *argv[])
  {
  int ret, vendor, product, counter;  /* Hilfsvariable */
  int debug;                          /* Debug-Ausgabe ein/aus */ 
  int one_read, voc_only, mrtg_only;  /* Flags fuer Optionen */
  struct usb_device *dev;             /* USB-Geraet; Airsensor */
  char buf[1000];                     /* Datenpuffer */
  unsigned short voc = 0;

  /* Variablen und Flags initialisieren */
  dev = NULL;        /* Device init */
  counter = 10;      /* Startwert Zaehler */
  debug = 0;         /* keine Debug-Ausgabe */
  voc_only = 0;      /* normale Ausgabe */
  mrtg_only = 0;     /* normale Ausgabe */
  one_read = 0;      /* Endlosschleife */

  vendor = 0x03eb;   /* Vendor-ID Airsensor */
  product = 0x2013;  /* Product-ID Airsensor */

  /* Strg-C abfangen */
  signal(SIGTERM, release_usb_device);

  /* Kommandozeilen-Optionen einlesen */
  while ((argc > 1) && (argv[1][0] == '-'))
    {
    switch (argv[1][1])
      {
      case 'd': debug = 1; break;
      case 'v': voc_only = 1; break;
      case 'm': mrtg_only = 1; break;
      case 'o': one_read = 1; break;
      case 'h': usage(); break;
      }
    ++argv;
    --argc;
    }

  if (debug)
    { 
    printout("DEBUG: Active", 0);
    printout("DEBUG: Init USB", 0);
    }
  usb_init();

  do {
    /* Airsensor suchen */
    dev = find_device(vendor, product);
    sleep(1);

    /* Falls Airsensor nicht gefunden, mehrmals versuchen */
    if (dev == NULL && debug)
      printout("DEBUG: No device found, wait 10sec...", 0);
    sleep(10);
    counter--;
    }  while (dev == NULL && counter > 0);
  if (dev == 0)
    {
    printout("Error: Device not found", 0);
    exit(1);
    }

  if (debug)
    printout("DEBUG: USB device found", 0);

  /* Airsensor oeffnen */
  devh = usb_open(dev);
  assert(devh);
 
  /* Device belegen */
  ret = usb_get_driver_np(devh, 0, buf, sizeof(buf));
  if (ret == 0)
    ret = usb_detach_kernel_driver_np(devh, 0);

  ret = usb_claim_interface(devh, 0);
  if (ret != 0)
    {
    printout("Error: claim failed with error: ", ret);
    exit(1);
    }

  if (debug)
    printout("DEBUG: Read any remaining data from USB", 0);
  ret = usb_interrupt_read(devh, 0x00000081, buf, 0x0000010, 1000);
  if (debug)
    printout("DEBUG: Return code from USB read: ", ret);

  for(;;)
    {
    /* USB COMMAND TO REQUEST DATA - @h*TR */
    if (debug)
      printout("DEBUG: Write data to device", 0);

    memcpy(buf, "\x40\x68\x2a\x54\x52\x0a\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40", 0x0000010);
    ret = usb_interrupt_write(devh, 0x00000002, buf, 0x0000010, 1000);

    if (debug)
      {
      printout("DEBUG: Return code from USB write: ", ret);
      printout("DEBUG: Read USB", 0);
      }
    ret = usb_interrupt_read(devh, 0x00000081, buf, 0x0000010, 1000);
    if (debug)
      printout("DEBUG: Return code from USB read: ", ret);

    if ( !((ret == 0) || (ret == 16)))
      {
      if (voc_only)
        { printf("0\n"); } 
      else if (mrtg_only)
        { printf("0\n0\n0\nairsensor\n"); } 
      else
        { printout("ERROR: Invalid result code: ", ret); }
      }

    if (ret == 0)
      {
      if (debug)
        printout("DEBUG: Read USB", 0);
      sleep(1);
      ret = usb_interrupt_read(devh, 0x00000081, buf, 0x0000010, 1000);
      if (debug)
        printout("DEBUG: Return code from USB read: ", ret);
      }

    voc = (buf[3] << 8) + buf[2];  
    sleep(1);
    if (debug)
      printout("DEBUG: Read USB [flush]", 0);

    ret = usb_interrupt_read(devh, 0x00000081, buf, 0x0000010, 1000);
    if (debug)
      printout("DEBUG: Return code from USB read: ", ret);

    // According to AppliedSensor specifications the output range is between 450 and 2000
    // So only printout values between this range

    if (voc >= 450 && voc <= 2001)
      {
      if (voc_only)
        { printf("%d\n", voc); }
      else if (mrtg_only)
        { printf("%d\n0\n0\nairsensor\n", voc); }
      else
        { printout("RESULT: OK, VOC: ",voc); }
      }
    else
      {
      if (voc_only)
        { printf("0\n"); }
      else if (mrtg_only)
        { printf("0\n0\n0\nairsensor\n"); } 
      else
        { printout("RESULT:  Error value out of range, VOC: ",voc); }
      }

    /* Falls nur einmal Lesen eingestellt, exit */
    if (one_read)
      release_usb_device(0);

    /* Pause, dann neuer Schleifendurchlauf */
    sleep(10);
    }
  }

