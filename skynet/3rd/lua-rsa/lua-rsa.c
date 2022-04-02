//  RSA 加密 ///

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/err.h>

#include <lua.h>
#include <lauxlib.h>

#define DATA_BLOCK_BUFSIZE 2048

// 填充模式。
// c#/unity3d 相关资料：
//      RSAEncryptionPadding        https://msdn.microsoft.com/zh-CN/library/system.security.cryptography.rsaencryptionpadding(v=vs.110).aspx
//      RSAEncryptionPaddingMode    https://msdn.microsoft.com/zh-cn/library/system.security.cryptography.rsaencryptionpaddingmode(v=vs.110).aspx
//const int padding = RSA_PKCS1_PADDING; // 最大明文长度：RSA_size(rsa) – 11
const int padding = RSA_PKCS1_OAEP_PADDING; // 最大明文长度：RSA_size(rsa) – 41
// const int padding = RSA_NO_PADDING; // 最大明文长度：RSA_size(rsa)

// 用公钥加密
int public_encrypt(const unsigned char* data, int data_len, const unsigned char* key, unsigned char* encrypted,int buf_len)
{
	int ret = -1;
	BIO* keybio = BIO_new_mem_buf(key, -1);
	if (keybio != NULL)
	{
		RSA* rsa = NULL;
		rsa = PEM_read_bio_RSA_PUBKEY(keybio, &rsa, NULL, NULL);
		if (rsa != NULL)
		{
		    int rsa_len = RSA_size(rsa);
		    if (buf_len < rsa_len)
		    {
		        printf("\npublic_encrypt error:buf need %d bytes ,but only %d !\n",rsa_len,buf_len);
                RSA_free(rsa);
                BIO_free_all(keybio);
                return -1;
            }

			ret = RSA_public_encrypt(data_len, data, encrypted, rsa, padding);
			RSA_free(rsa);
		}
		else
		{
		    printf("\npublic_encrypt:PEM_read_bio_RSA_PUBKEY error!\n");
		}
		BIO_free_all(keybio);
	}
	else
	{
        printf("\npublic_encrypt:BIO_new_mem_buf error!\n");
	}
    return ret;
}

// 用私钥解密
int private_decrypt(const unsigned char* enc_data, int data_len, const unsigned char* key, unsigned char* decrypted,int buf_len)
{
	int ret = -1;
	BIO* keybio = BIO_new_mem_buf(key, -1);
	if (keybio != NULL)
	{
		RSA* rsa = NULL;
		rsa = PEM_read_bio_RSAPrivateKey(keybio, &rsa, NULL, NULL);
		if (rsa != NULL)
		{
		    int rsa_len = RSA_size(rsa);
		    if (buf_len < rsa_len)
		    {
		        printf("\nprivate_decrypt error:buf need %d bytes ,but only %d !\n",rsa_len,buf_len);
                RSA_free(rsa);
                BIO_free_all(keybio);
                return -1;
            }

			ret = RSA_private_decrypt(data_len, enc_data, decrypted, rsa, padding);
			RSA_free(rsa);
		}
		else
		{
		    printf("\nprivate_decrypt:PEM_read_bio_RSAPrivateKey error!\n");
		}
		BIO_free_all(keybio);
	}
	else
	{
        printf("\nprivate_decrypt:BIO_new_mem_buf error!\n");
	}
    return ret;
}

//用公钥加密
// lpublic_encrypt(data,key)
static int lpublic_encrypt(lua_State *L) {

    size_t data_len = 0;
    const char * data = lua_tolstring(L,1,&data_len);
    if (!data)
    {
        printf("\nlpublic_encrypt error:data is null!\n");
        return 0;
    }

    size_t key_len = 0;
    const char * key = lua_tolstring(L,2,&key_len);
    if (!key)
    {
        printf("\nlpublic_encrypt error:key is null!\n");
        return 0;
    }

    unsigned char buf[DATA_BLOCK_BUFSIZE] = {0};

    int en_data = public_encrypt((unsigned char *)data,data_len,(unsigned char *)key,(unsigned char *)buf,DATA_BLOCK_BUFSIZE);

    if (en_data <= 0)
    {
        printf("\nlpublic_encrypt error:result len is %d !\n",en_data);
        return 0;
    }

    lua_pushlstring(L,(const char *)buf,en_data);

    return 1;
}

//用私钥解密
// lprivate_decrypt(data,key)
static int lprivate_decrypt(lua_State *L) {

    size_t data_len = 0;
    const char * data = lua_tolstring(L,1,&data_len);
    if (!data)
    {
        printf("\nlprivate_decrypt error:data is null!\n");
        return 0;
    }

    size_t key_len = 0;
    const char * key = lua_tolstring(L,2,&key_len);
    if (!key)
    {
        printf("\nlprivate_decrypt error:key is null!\n");
        return 0;
    }

    unsigned char buf[DATA_BLOCK_BUFSIZE] = {0};

    int en_data = private_decrypt((unsigned char *)data,data_len,(unsigned char *)key,(unsigned char *)buf,DATA_BLOCK_BUFSIZE);

    if (en_data <= 0)
    {
        printf("\nlprivate_decrypt error:result len is %d !\n",en_data);
        return 0;
    }

    lua_pushlstring(L,(const char *)buf,en_data);

    return 1;
}

int luaopen_rsa(lua_State *L) {
  luaL_checkversion(L);

  luaL_Reg l[] = {
    {"public_encrypt", lpublic_encrypt},
    {"private_decrypt", lprivate_decrypt},
    { NULL, NULL },
  };

  luaL_newlib(L, l);
  return 1;
}

