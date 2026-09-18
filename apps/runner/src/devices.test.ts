import { describe, expect, it } from 'vitest';
import { adbPath, installAndRun, parseDevices } from './devices.js';

describe('phones', () => {
  it('reads the phones adb lists, with the model when it says one', () => {
    const output = [
      'List of devices attached',
      'A2VQ024204000993       device product:redfin model:Pixel_5 device:redfin transport_id:3',
      'emulator-5554          device product:sdk_gphone64 model:sdk_gphone64_x86_64 transport_id:1',
      '4a1c9d20               unauthorized',
      '',
    ].join('\n');
    expect(parseDevices(output)).toEqual([
      { id: 'A2VQ024204000993', state: 'device', name: 'Pixel 5' },
      { id: 'emulator-5554', state: 'device', name: 'sdk gphone64 x86 64' },
      { id: '4a1c9d20', state: 'unauthorized', name: '4a1c9d20' },
    ]);
    expect(parseDevices('List of devices attached\n\n')).toEqual([]);
  });

  it('looks for adb where Android puts it', () => {
    expect(adbPath({ ANDROID_SDK_ROOT: '/nowhere' })).toMatch(/adb/);
  });

  it('tells the user what to do, instead of repeating Android error codes', async () => {
    const adb = (out: string) => async () => ({ code: 0, out });
    const app = { apkPath: 'a.apk', packageName: 'dev.demo' };

    await expect(installAndRun(app, 'adb', adb('Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match]'))).rejects.toThrow(/uninstall it from the phone/i);
    await expect(installAndRun(app, 'adb', adb('adb: device unauthorized.'))).rejects.toThrow(/Allow USB debugging/i);
    await expect(installAndRun(app, 'adb', adb('Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE]'))).rejects.toThrow(/refused/i);
  });

  it('opens the app once it is installed', async () => {
    const calls: string[][] = [];
    const exec = async (_bin: string, args: string[]) => {
      calls.push(args);
      return { code: 0, out: args.includes('install') ? 'Success' : 'Events injected: 1' };
    };
    const message = await installAndRun({ apkPath: 'a.apk', packageName: 'dev.demo', deviceId: 'PHONE1' }, 'adb', exec);
    expect(message).toMatch(/opened on the phone/i);
    expect(calls[0]).toEqual(['-s', 'PHONE1', 'install', '-r', 'a.apk']);
    expect(calls[1]).toContain('monkey');
  });

  it('says where to find the app when the phone cannot open it by itself', async () => {
    const exec = async (_bin: string, args: string[]) => ({ code: 0, out: args.includes('install') ? 'Success' : 'No activities found to run' });
    await expect(installAndRun({ apkPath: 'a.apk', packageName: 'dev.demo' }, 'adb', exec)).resolves.toMatch(/home screen/i);
  });
});
