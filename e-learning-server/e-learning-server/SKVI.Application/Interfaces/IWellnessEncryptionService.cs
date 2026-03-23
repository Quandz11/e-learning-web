namespace SKVI.Application.Interfaces;

public interface IWellnessEncryptionService
{
    string Encrypt(string plainText);
    string Decrypt(string cipherText);
}

