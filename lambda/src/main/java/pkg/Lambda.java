package pkg;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class Lambda implements RequestStreamHandler {
    private final JsonMapper mapper = JsonMapper.builder().configure(MapperFeature.ACCEPT_CASE_INSENSITIVE_PROPERTIES, true).build();

    @Override
    public void handleRequest(final InputStream input, final OutputStream output, final Context context) throws IOException {
        var event = mapper.readValue(input, SQSEvent.class);
        var msg = mapper.readValue(event.getRecords().get(0).getBody(), TestMessage.class);
        System.out.println(msg);
        output.close();
    }
}
