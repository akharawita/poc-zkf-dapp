export const getVerificationKey = async () => {
  const verificationKeyPath = `zksnarks/verification_key.json`;
  return await fetch(verificationKeyPath).then(function (res) {
    return res.json();
  });
};
