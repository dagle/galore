// helper C functions for gmime
#include <glib.h>
#include <gmime/gmime.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

int gmime_is_message_part(GMimeObject *obj){
	return GMIME_IS_MESSAGE_PART(obj);
}

int gmime_is_message_partial(GMimeObject *obj){
	return GMIME_IS_MESSAGE_PARTIAL(obj);
}

int gmime_is_multipart(GMimeObject *obj){
	return GMIME_IS_MULTIPART(obj);
}

int gmime_is_part(GMimeObject *obj){
	return GMIME_IS_PART(obj);
}

int gmime_is_multipart_signed(GMimeObject *obj){
	return GMIME_IS_MULTIPART_SIGNED(obj);
}

int gmime_is_multipart_encrypted(GMimeObject *obj){
	return GMIME_IS_MULTIPART_ENCRYPTED(obj);
}

GMimeObject *message_part(GMimeMessage *message){
	return message->mime_part;
}

uint multipart_len(GMimeMultipart *mp){
	return mp->children->len;
}

GMimeObject *multipart_child(GMimeMultipart *mp, int i){
	return mp->children->pdata[i];
}
