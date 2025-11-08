const listDevices = async (forceAsk) => {
  const options= [];
  try {
    const permissionStatus = await navigator.permissions.query({ name: 'microphone' });
    if (forceAsk === true || permissionStatus.state !== 'granted') {
      await navigator.mediaDevices.getUserMedia({ audio: true });
    }

    const devices = await navigator.mediaDevices.enumerateDevices();
    devices.forEach((device) => {
      if (device.kind === 'audiooutput') {
        options.push(device);
      }
    });

    // Firefox requiring the prompt?
    if (options.length < 2 && !forceAsk) {
      return listDevices(true);
    }
  } catch (_e) {
    return options;
  }

  return Promise.resolve(options);
}


export default {
  listDevices
};

